
UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Dragon_Vocalizations_Teen_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void AcidTeenGlideStop(){}

	UFUNCTION(BlueprintEvent)
	void AcidTeenGlideStart(){}

	UFUNCTION(BlueprintEvent)
	void AcidTeenWingFlapDown(){}

	UFUNCTION(BlueprintEvent)
	void AcidTeenWingFlapUp(){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepRelease(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnVocalization(FDragonVocalizationParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UDragonMovementAudioComponent DragonMoveAudioComp;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter DragonRiderPlayer;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DragonMoveAudioComp = UDragonMovementAudioComponent::Get(HazeOwner);
		auto DragonComp = Cast<ATeenDragon>(HazeOwner).GetDragonComponent();
		DragonRiderPlayer = DragonComp.IsAcidDragon() ? Game::GetMio() : Game::GetZoe();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, DragonRiderPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return !DragonMoveAudioComp.IsMovementBlocked(EMovementAudioFlags::Breathing);			
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		return DragonMoveAudioComp.IsMovementBlocked(EMovementAudioFlags::Breathing);	
	}
}