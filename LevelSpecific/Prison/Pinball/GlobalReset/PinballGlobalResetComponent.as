event void FPinballOnGlobalReset();

UCLASS(NotBlueprintable)
class UPinballGlobalResetComponent : UActorComponent
{
	UPROPERTY()
	FPinballOnGlobalReset PreActivateProgressPoint;

	UPROPERTY()
	FPinballOnGlobalReset PostActivateProgressPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!Pinball::bUseFastGameOver)
			return;

		UPinballGlobalResetManager::Get().GlobalResetComponents.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(!Pinball::bUseFastGameOver)
			return;

		if(EndPlayReason == EEndPlayReason::Destroyed && !(World.IsTearingDown() || Owner.Level.IsBeingRemoved() || !Owner.Level.IsLevelActive()))
		{
			check(false, "Can't destroy an actor that implements GlobalReset!");
			return;
		}
		
		UPinballGlobalResetManager::Get().GlobalResetComponents.RemoveSingle(this);
	}
};