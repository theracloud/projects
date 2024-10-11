output "pet-name" {
  value = random_pet.my-pet.id
  description = "record the value of pet id"
}