
UCLASS(Abstract)
class UPlayer_Movement_Sand_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSlideEnterWater(FHazeAudioWaterMovementVolumeData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSlideExitWater(FHazeAudioWaterMovementVolumeData Data){}

	/* END OF AUTO-GENERATED CODE */

	UHazeMovementComponent MoveComp;
	USandSharkPlayerComponent PlayerSandComp;
	UPlayerSlideComponent PlayerSlideComp;

	bool bWasInSand = false;

	UFUNCTION(BlueprintEvent)
	void OnEnterSand() {};

	UFUNCTION(BlueprintEvent)
	void OnExitSand() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		PlayerSlideComp = UPlayerSlideComponent::Get(PlayerOwner);
	}

	private bool EnsurePlayerSandComp()
	{
		if(PlayerSandComp == nullptr)
		{
			PlayerSandComp = USandSharkPlayerComponent::Get(PlayerOwner);
			return PlayerSandComp != nullptr;		
		}

		return true;
	}

	private void QueryInSand()
	{
		if(!EnsurePlayerSandComp())
			return;
		
		// Sliding takes prescedence
		if(PlayerSlideComp.IsSlideActive())
			return;

		const bool bIsInSand = PlayerSandComp.bHasTouchedSand;
		if(!bWasInSand && bIsInSand)
			OnEnterSand();
		else if(bWasInSand && !bIsInSand)
			OnExitSand();

		bWasInSand = bIsInSand;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		QueryInSand();
	}
}