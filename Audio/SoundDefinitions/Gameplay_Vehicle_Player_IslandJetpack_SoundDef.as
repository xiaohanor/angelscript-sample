
UCLASS(Abstract)
class UGameplay_Vehicle_Player_IslandJetpack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void HitPhasableWall(){}

	UFUNCTION(BlueprintEvent)
	void FuelFullyCharged(){}

	UFUNCTION(BlueprintEvent)
	void FuelStartRecharge(){}

	UFUNCTION(BlueprintEvent)
	void FuelEmpty(){}

	UFUNCTION(BlueprintEvent)
	void JetpackDash(){}

	UFUNCTION(BlueprintEvent)
	void ThrusterBoostFirstActivation(){}

	UFUNCTION(BlueprintEvent)
	void ThrusterBoostStop(){}

	UFUNCTION(BlueprintEvent)
	void ThrusterBoostStart(){}

	UFUNCTION(BlueprintEvent)
	void ThrusterCancel(){}

	UFUNCTION(BlueprintEvent)
	void JetpackActivated(){}

	UFUNCTION(BlueprintEvent)
	void JetpackDeactivated(){}

	/* END OF AUTO-GENERATED CODE */

	FVector PreviousPosition;
	float LastVelocity;

	UPROPERTY(BlueprintReadOnly)
	AIslandJetpack Jetpack;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter JetpackPlayer;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Jetpack = Cast<AIslandJetpack>(HazeOwner);

		JetpackPlayer = Jetpack.Player;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, JetpackPlayer);
	}

	UFUNCTION(BlueprintPure)
	void UpdateAudioComponentVelocity(UHazeAudioEmitter AudioEmitter, const float&in DeltaSeconds, const float&in MaxSpeed, float&out HorizontalVelocity, float&out HorizontalVelocityDelta)
	{
		auto AudioComponent = AudioEmitter.GetAudioComponent();
		FVector CurrentPosition = AudioComponent.WorldLocation;
		FVector VelocityVector = CurrentPosition - PreviousPosition;
		VelocityVector.Z = 0;

		float Velocity = VelocityVector.Size();
		float CurrentVelocity = Velocity / DeltaSeconds;
		HorizontalVelocityDelta = CurrentVelocity - LastVelocity;
		
		HorizontalVelocity = MaxSpeed == 0 ? CurrentVelocity : Math::Clamp((CurrentVelocity / MaxSpeed), -1, 1);
		// NormalizedDelta = MaxSpeedDelta == 0 ? HorizontalVelocityDelta : Math::Clamp((HorizontalVelocityDelta / MaxSpeedDelta), -1, 1);

		PreviousPosition = CurrentPosition;
		LastVelocity = CurrentVelocity;
	}

}