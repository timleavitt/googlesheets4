new <- function(id, ...) {
  schema <- .tidy_schemas[[id]]
  if (is.null(schema)) {
    abort(glue("Can't find a tidy schema with id {sq(id)}"))
  }
  dots <- list2(...)

  check_against_schema(dots, schema = schema)

  structure(
    dots,
    # explicit 'list' class is a bit icky but makes jsonlite happy
    # in various vctrs futures, this could need revisiting
    class = c(id_as_class(id), "googlesheets4_schema", "list"),
    schema = schema
  )
}

# TODO: if it proves necessary, this could do more meaningful checks
check_against_schema <- function(x, schema = NULL, id = NA_character_) {
  schema <- schema %||%
    .tidy_schemas[[id %|% id_from_class(x)]] %||%
    attr(x, "schema")
  if (is.null(schema)) {
    msg <- glue("
    Trying to check an object of class {class_collapse(x)}, \\
    but can't get a schema.
    ")
    abort(msg)
  }
  unexpected <- setdiff(names(x), schema$property)
  if (length(unexpected) > 0) {
    msg <- glue("
    Properties not recognized for the {sq(attr(schema, 'id'))} schema:
      * {glue_collapse(unexpected, sep = ', ')}
    ")
    abort(msg)
  }
  x
}

id_as_class <- function(id) glue("googlesheets4_schema_{id}")

id_from_class <- function(x) {
  m <- grep("^googlesheets4_schema_", class(x), value = TRUE)[[1]]
  sub("^googlesheets4_schema_", "", m)
}

# patch ----
patch <- function(x, ...) {
  UseMethod("patch")
}

#' @export
patch.default <- function(x, ...) {
  stop_glue("
  Don't know how to {bt('patch()')} an object of class {class_collapse(x)}
  ")
}

#' @export
patch.googlesheets4_schema <- function(x, ...) {
  dots <- list2(...)
  x[names(dots)] <- dots
  check_against_schema(x)
}
