commit_version_impl <- function(additional_commit_message = "") {
  check_only_staged(c("DESCRIPTION", "NEWS.md"))

  if (is_last_commit_bump()) {
    ui_info("Resetting to previous commit")
    git2r::reset(git2r::revparse_single(revision = "HEAD^"))
    amending <- TRUE
  } else {
    amending <- FALSE
  }

  git2r::add(".", c("DESCRIPTION", "NEWS.md"))
  if (length(git2r::status(".", unstaged = FALSE, untracked = FALSE)$staged) > 0) {
    ui_info("Committing changes")
    if (additional_commit_message != "") {
      git2r::commit(".", get_commit_message())
    } else {
      git2r::commit(".", sprintf("%s - %s", additional_commit_message, get_commit_message()))
    }
  }

  amending
}

is_last_commit_bump <- function() {
  git2r::last_commit()$message == get_commit_message()
}

get_commit_message <- function(version) {
  desc <- desc::desc(file = "DESCRIPTION")
  version <- desc$get_version()

  paste0("Bump version to ", version)
}

check_clean <- function(forbidden_modifications) {
  status <- git2r::status(".", unstaged = TRUE, untracked = TRUE)
  stopifnot(!any(forbidden_modifications %in% unlist(status)))
}

check_only_staged <- function(allowed_modifications) {
  staged <- git2r::status(".", unstaged = FALSE, untracked = FALSE)$staged
  stopifnot(all(names(staged) == "modified"))

  modified <- staged$modified
  stopifnot(all(modified %in% allowed_modifications))
}
