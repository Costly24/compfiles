import Std.Data.String.Basic
import Std.Tactic.Lint
import Lean.Environment
import Mathlib.Data.String.Defs
import MathPuzzles.Meta.ProblemExtraction
import Lean.Meta.Basic

open Lean Core Elab Command Std.Tactic.Lint

structure PuzzleInfo where
  name : String
  solutionUrl : String
  problemUrl : String
  proved : Bool


def olean_path_to_github_url (path: String) : String :=
  let pfx := "./build/lib/"
  let sfx := ".olean"
  assert!(pfx.isPrefixOf path)
  assert!(sfx.data.isSuffixOf path.data)
  "https://github.com/dwrensha/math-puzzles-in-lean4/blob/main/" ++
    ((path.stripPrefix pfx).stripSuffix sfx) ++ ".lean"

open System in
instance : ToExpr FilePath where
  toTypeExpr := mkConst ``FilePath
  toExpr path := mkApp (mkConst ``FilePath.mk) (toExpr path.1)


elab "compileTimeSearchPath" : term =>
  return toExpr (← searchPathRef.get)

def HEADER : String :=
 "<!DOCTYPE html><html><head> <meta name=\"viewport\" content=\"width=device-width\">" ++
 "<title>Math Puzzles in Lean 4</title>" ++
 "</head>"

unsafe def main (_args : List String) : IO Unit := do
  IO.FS.createDirAll "_site"
  IO.FS.createDirAll "_site/problems"

  let module := `MathPuzzles
  searchPathRef.set compileTimeSearchPath

  withImportModules #[{module}] {} (trustLevel := 1024) fun env =>
    let ctx := {fileName := "", fileMap := default}
    let state := {env}
    Prod.fst <$> (CoreM.toIO · ctx state) do
      let mst ← MathPuzzles.Meta.extractProblems

      let mut infos : List PuzzleInfo := []
      let pkg := `MathPuzzles
      let modules := env.header.moduleNames.filter (pkg.isPrefixOf ·)
      let baseurl := ((← IO.getEnv "GITHUB_PAGES_BASEURL").getD "")

      for m in modules do
        if m ≠ pkg && m ≠ `MathPuzzles.Meta.ProblemExtraction then do
          let p ← findOLean m
          let solutionUrl := olean_path_to_github_url p.toString
          IO.println s!"MODULE: {m}"
          let problem_file := s!"problems/{m}.lean.txt"
          let problemUrl := s!"{baseurl}{problem_file}"

          let problem_src := (mst.find? m).getD ""
          let h ← IO.FS.Handle.mk ("_site/" ++ problem_file) IO.FS.Mode.write
          h.putStrLn problem_src
          h.flush

          let mut proved := true
          let decls ← getDeclsInPackage m
          for d in decls do
            let c ← getConstInfo d
            match c.value? with
            | none => pure ()
            | some v => do
                 if v.hasSorry then proved := false
          infos := ⟨m.toString.stripPrefix "MathPuzzles.",
                    solutionUrl, problemUrl, proved⟩ :: infos
      -- now write the file
      let num_proved := (infos.filter (·.proved)).length
      let commit_sha := ((← IO.getEnv "GITHUB_SHA").getD "GITHUB_SHA_env_var_not_found")
      let commit_url :=
        s!"https://github.com/dwrensha/math-puzzles-in-lean4/commit/{commit_sha}"

      let h ← IO.FS.Handle.mk "_site/index.html" IO.FS.Mode.write
      h.putStr HEADER
      h.putStr "<body>"
      h.putStr $ "<p>This is a dashboard for the " ++
         "<a href=\"https://github.com/dwrensha/math-puzzles-in-lean4\">" ++
         "Math Puzzles in Lean 4</a> repository.</p>"
      h.putStr s!"<p>(Generated by commit <a href=\"{commit_url}\">{commit_sha}</a>.)<p>"
      h.putStr s!"<p>{num_proved} / {infos.length} problems have a complete solution.<p>"
      h.putStr "<ul>"
      for info in infos.reverse do
        h.putStr "<li>"
        h.putStr s!"<a href=\"{info.solutionUrl}\">"
        if info.proved then
          h.putStr "✅  "
        else
          h.putStr "❌  "
        h.putStr "</a>"
        h.putStr s!"<a href=\"{info.problemUrl}\">{info.name}</a>"
        h.putStr "</li>"
      h.putStr "</ul>"
      h.putStr "</body></html>"
      pure ()
