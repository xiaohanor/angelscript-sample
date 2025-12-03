class UDebrisFallingPlayerComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	UAnimSequence FallingAnimation;

	UPROPERTY(Category = "Setup")
	UAnimSequence GrappleAnimation;

	bool bPlayersHaveGrappled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};