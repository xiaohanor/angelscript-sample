
UCLASS(Abstract)
class UGameplay_Projectile_Enemy_Island_Mech_Shared_Impact_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnBulletReflectedAI(FIslandRedBlueWeaponOnBulletImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnBulletImpactAI(FIslandRedBlueWeaponOnBulletImpactAIParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AIslandRedBlueWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Weapon = Cast<AIslandRedBlueWeapon>(HazeOwner);	
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Sidescroller"))
	bool IsSidescroller()
	{
		AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if(FullscreenPlayer != nullptr)
			return FullscreenPlayer.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller;

		return false;
	}

	UFUNCTION(BlueprintCallable)
	void SetEmitterScreenPanning(UHazeAudioEmitter&in Emitter)
	{
		if(Emitter == nullptr || !IsSidescroller())
			return;

		FVector2D _;
		float X = 0.0;
		float _Y = 0.0;
		if(Audio::GetScreenPositionRelativePanningValue(Emitter.GetEmitterLocation(), _, X, _Y))
			Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
	}
}