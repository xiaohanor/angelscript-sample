
UCLASS(Abstract)
class UGameplay_Vehicle_HackableObject_TazerBot_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLandedAfterLaunch(){}

	UFUNCTION(BlueprintEvent)
	void OnLaunched(){}

	UFUNCTION(BlueprintEvent)
	void OnRetracting(){}

	UFUNCTION(BlueprintEvent)
	void OnFullyExtended(){}

	UFUNCTION(BlueprintEvent)
	void OnExtending(){}

	UFUNCTION(BlueprintEvent)
	void OnDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void OnImpact(){}

	/* END OF AUTO-GENERATED CODE */

	ATazerBot TazerBot;
	URemoteHackingResponseComponent HackingComp;
	UHazeMovementComponent MoveComp;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter BaseEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter TurretEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter ElectricityEmitter;

	UFUNCTION(BlueprintEvent)
	void OnHackStart() {};

	UFUNCTION(BlueprintEvent)
	void OnHackStop() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TazerBot = Cast<ATazerBot>(HazeOwner);
		MoveComp = UHazeMovementComponent::Get(Game::GetMio());

		HackingComp = URemoteHackingResponseComponent::Get(TazerBot);
		HackingComp.OnHackingStarted.AddUFunction(this, n"OnHackStart");
		HackingComp.OnHackingStopped.AddUFunction(this, n"OnHackStop");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BaseEmitter.AudioComponent.AttachToComponent(TazerBot.MeshComponent, n"Base");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{

	}

	UFUNCTION(BlueprintPure)
	void GetPlayerInputs(float&out Movement, float&out Camera)
	{
		if(HackingComp.bHacked)
		{
			Movement = MoveComp.GetSyncedMovementInputForAnimationOnly().Size();
			Camera = Game::GetMio().CameraInput.X;
		}
		else
		{
			Movement = 0.0;
			Camera = 0.0;
		}
	}

	UFUNCTION(BlueprintPure)
	float GetPoleExtensionAlpha()
	{
		return TazerBot.GetRodExtensionFraction();
	}
}