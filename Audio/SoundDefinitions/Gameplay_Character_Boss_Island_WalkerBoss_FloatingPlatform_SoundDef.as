
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_WalkerBoss_FloatingPlatform_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerFloatingPlatform FloatingPlatform;
	AIslandWalkerArenaLimits Arena;

	UFUNCTION(BlueprintPure)
	float GetSurfaceHeight() 
	{
		return Arena.FloodedPoolSurfaceHeight;
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnter (AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLeave (AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
        Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();

		FloatingPlatform = Cast<AIslandWalkerFloatingPlatform>(HazeOwner);
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FloatingPlatform.Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		FloatingPlatform.Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
    private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
                           const FHitResult&in SweepResult)
    {
        if (!FloatingPlatform.bIsActivated)
            return;
        auto Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		OnPlayerEnter(Player);
    }

	UFUNCTION()
    private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
                           UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
        if (!FloatingPlatform.bIsActivated)
            return;
        auto Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		OnPlayerLeave(Player);
    }


}