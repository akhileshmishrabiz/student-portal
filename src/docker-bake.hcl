target "app" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["366140438193.dkr.ecr.ap-south-1.amazonaws.com/student-portal:k8s2"]
  no-cache = true
  platforms = ["linux/amd64"]
}

