UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class UWindDirectionResponseComponent : UActorComponent
{
	private UWindDirectionComponent WindDirectionComp;
	WindDirectionChanged OnWindDirectionChanged;

	FVector WindDirection;
	FVector Location;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WindDirectionComp = UWindDirectionComponent::GetOrCreate(Game::GetMio());
		WindDirectionComp.OnWindDirectionChanged.AddUFunction(this, n"WindDirectionChanged");
	}

	UFUNCTION()
	void WindDirectionChanged(FVector InWindDirection, FVector InLocation)
	{
		WindDirection = InWindDirection;
		Location = InLocation;
		
		OnWindDirectionChanged.Broadcast(InWindDirection, InLocation);
	}
}