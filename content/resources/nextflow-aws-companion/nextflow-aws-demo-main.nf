process SAY_HELLO {
  output:
  path "hello.txt"

  script:
  """
  echo "hello from Nextflow" > hello.txt
  """
}

workflow {
  SAY_HELLO()
}
