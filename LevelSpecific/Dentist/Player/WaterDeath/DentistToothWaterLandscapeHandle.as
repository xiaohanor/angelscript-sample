namespace Dentist
{
	UFUNCTION(BlueprintPure, Category = "Dentist", DisplayName = "Dentist Get Chocolate Water Landscape")
	ALandscape GetChocolateWaterLandscape()
	{
		const ADentistToothWaterLandscapeHandle Handle = TListedActors<ADentistToothWaterLandscapeHandle>().Single;
		if(Handle == nullptr)
			return nullptr;

		return Handle.ChocolateWaterLandscape.Get();
	}

	UFUNCTION(BlueprintPure, Category = "Dentist", DisplayName = "Dentist Get Chocolate Water Height")
	float GetChocolateWaterHeight(FVector Location)
	{
		float32 ChocolateWaterHeight = 0;
		GetChocolateWaterLandscape().GetHeightAtLocation(Location, ChocolateWaterHeight);
		return ChocolateWaterHeight;
	}

#if EDITOR
	ALandscape GetChocolateWaterLandscapeEditor()
	{
		auto Actors = Editor::GetAllEditorWorldActorsOfClass(ADentistToothWaterLandscapeHandle);
		if(Actors.IsEmpty())
			return nullptr;

		return Actors[0].ChocolateWaterLandscape.Get();
	}
#endif
};

UCLASS(NotBlueprintable)
class ADentistToothWaterLandscapeHandle : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ALandscape> ChocolateWaterLandscape;
}