class UTeenDragonWaterMovementAudioCapability : UHazePlayerCapability
{
	ATeenDragon DragonActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		DragonActor = Cast<ATeenDragon>(DragonComp.DragonMesh.Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPrimitiveComponent WaterColliderComp = UPrimitiveComponent::Get(DragonActor, n"WaterCollision");
		WaterColliderComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}
}