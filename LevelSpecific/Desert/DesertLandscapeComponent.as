enum ESandSharkLandscapeLevel
{
	Lower,
	Upper,
	Secondary
}

UCLASS()
class UDesertLandscapeComponent : UActorComponent
{
	private ALandscape _Landscape;

	UPROPERTY(EditAnywhere)
	ESandSharkLandscapeLevel Level;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		_Landscape = Cast<ALandscape>(Owner);
		auto Manager = Desert::GetManager();
		Manager.Landscapes.Add(this);
		devCheck(!Manager.LandscapesByLevel.Contains(Level), f"Trying to add desert landscape {Name} for landscapelevel {Level}, but manager already has a landscape for this landscapelevel!");
		Desert::GetManager().LandscapesByLevel.Add(Level, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Desert::GetManager().Landscapes.RemoveSingleSwap(this);
		Desert::GetManager().LandscapesByLevel.Remove(Level);
	}

	ALandscape GetLandscape() const property
	{
		if(_Landscape != nullptr)
			return _Landscape;

		return Cast<ALandscape>(Owner);
	}
};