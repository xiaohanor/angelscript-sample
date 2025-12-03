class USanctuaryDodgerLandComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Landing")
	bool bLanded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		bLanded = false;
	}

	void Land()
	{
		bLanded = true;
	}

	void TakeOff()
	{
		bLanded = false;
	}
}