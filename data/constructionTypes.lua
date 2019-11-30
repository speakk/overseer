return {
      walls = {
        name = "Walls",
        subItems = {
          wooden_wall = {
            name = "Wooden wall",
            requirements = {
              wood = 10,
              metal = 1
            },
            color = {0.9, 0.7, 0.1},
            hp = 100
          },
          iron_wall = {
            name = "Iron wall",
            requirements = {
              wood = 10,
              metal = 1
            },
            color = {0.5, 0.5, 0.55},
            hp = 500
          },
        }
      },
      doors = {
        name = "Doors",
        subItems = {
          wooden_door = {
            name = "Wooden door",
            requirements = {
              wood = 3
            },
            color = {0.9, 0.7, 0.1},
            hp = 100
          },
          stone_door = {
            name = "Stone door",
            requirements = {
              stone = 3
            },
            color = {0.8, 0.8, 0.8},
            hp = 200
          }
        }
      }
}
