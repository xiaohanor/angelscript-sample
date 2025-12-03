UCLASS(Abstract)
class USanctuaryWeeperLightBirdEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASanctuaryWeeperLightBird LightBird;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	USanctuaryWeeperLightBirdUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);
		Player = LightBird.Player;
		UserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
	}

	// Called when the bird starts illuminating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Illuminated() { }

	// Called when the bird stops illuminating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Unilluminated() { }

	UFUNCTION(BlueprintPure)
	float GetIlluminationRadius() const property
	{
		return LightBird.IlluminationRadius;
	}
}