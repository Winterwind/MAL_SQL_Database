import pandas as pd
import os

if __name__ == "__main__":
    # Check current path
    print("Current working directory:", os.getcwd())
    assert os.getcwd() == "/Users/ariandjahed/Databases/MAL_db", "not where you're supposed to be"

    # Read the two CSV files
    anime_sans_synopsis = pd.read_csv("anime.csv")
    anime_with_synopsis = pd.read_csv("anime_with_synopsis.csv")

    # Make new dataframe combining the proper columns from the other two
    anime_final = pd.DataFrame({
        "Anime_ID": anime_sans_synopsis["MAL_ID"],
        "Name": anime_sans_synopsis["Name"],
        "Score": anime_sans_synopsis["Score"],
        "Genre": anime_sans_synopsis["Genres"],
        "EngName": anime_sans_synopsis["English name"],
        "JapName": anime_sans_synopsis["Japanese name"],
        "Type": anime_sans_synopsis["Type"],
        "Episodes": anime_sans_synopsis["Episodes"],
        "Aired": anime_sans_synopsis["Aired"],
        "Premiered": anime_sans_synopsis["Premiered"],
        "Producer": anime_sans_synopsis["Producers"],
        "Licensor": anime_sans_synopsis["Licensors"],
        "Studio": anime_sans_synopsis["Studios"],
        "Source": anime_sans_synopsis["Source"],
        "Duration": anime_sans_synopsis["Duration"],
        "Rating": anime_sans_synopsis["Rating"],
        "Ranked": anime_sans_synopsis["Ranked"],
        "Popularity": anime_sans_synopsis["Popularity"],
        "Members": anime_sans_synopsis["Members"],
        "Favorites": anime_sans_synopsis["Favorites"],
        "Watching": anime_sans_synopsis["Watching"],
        "Completed": anime_sans_synopsis["Completed"],
        "OnHold": anime_sans_synopsis["On-Hold"],
        "Dropped": anime_sans_synopsis["Dropped"],
        "PlanToWatch": anime_sans_synopsis["Plan to Watch"],
        "Synopsis": anime_with_synopsis["sypnopsis"] # this mf really mispelled synopsis :skull:
    })

    # Handle multivalued attributes [Genre(s), Producer(s), Licensor(s), Studio(s)]
    anime_final["Genre"] = anime_final["Genre"].str.split(", ")
    anime_final["Producer"] = anime_final["Producer"].str.split(", ")
    anime_final["Licensor"] = anime_final["Licensor"].str.split(", ")
    anime_final["Studio"] = anime_final["Studio"].str.split(", ")
    # anime_final = anime_final.explode(["Genre", "Producer", "Licensor", "Studio"])
    anime_final = anime_final.explode("Genre")
    anime_final = anime_final.explode("Producer")
    anime_final = anime_final.explode("Licensor")
    anime_final = anime_final.explode("Studio")

    # Save the merged DataFrame to a new CSV file
    anime_final.to_csv("anime_final.csv", index=None)