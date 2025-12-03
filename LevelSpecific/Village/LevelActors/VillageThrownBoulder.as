event void FVillageThrownBoulderImpactEvent(AVillageThrownBoulder Boulder);

UCLASS(Abstract)
class AVillageThrownBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoulderRoot;

	UPROPERTY()
	FVillageThrownBoulderImpactEvent OnImpact;

	UPROPERTY()
	FVillageThrownBoulderImpactEvent OnBoulderThrown;

	UPROPERTY(EditAnywhere)
	float ThrowSpeed = 0.75;

	UPROPERTY(EditAnywhere)
	float ThrowHeight = 800.0;

	bool bThrown = false;
	FVector StartLocation;
	FVector TargetLocation;

	float ThrowAlpha = 0.0;

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY(EditAnywhere)
	bool bDisableOnImpact = true;

	bool bImpactTriggered = false;

	UPROPERTY(EditAnywhere)
	bool bBeamImpact = false;

	UFUNCTION()
	void ThrowBarebones()
	{
		UVillageThrownBoulderEffectEventHandler::Trigger_Thrown(this);
	}

	UFUNCTION()
	void ThrowBoulder(FVector TargetLoc)
	{
		if (bThrown)
			return;

		TargetLocation = TargetLoc;
		StartLocation = ActorLocation;
		bThrown = true;
		
		SetActorHiddenInGame(false);

		UVillageThrownBoulderEffectEventHandler::Trigger_Thrown(this);
	}

	UFUNCTION()
	void ThrowAtPlayer(AHazePlayerCharacter Player)
	{
		if (bThrown)
			return;

		TargetPlayer = Player;
		StartLocation = ActorLocation;
		bThrown = true;

		BP_ThrowAtPlayer();
		OnBoulderThrown.Broadcast(this);

		SetActorHiddenInGame(false);

		UVillageThrownBoulderEffectEventHandler::Trigger_Thrown(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ThrowAtPlayer() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bThrown)
			return;

		ThrowAlpha = Math::Clamp(ThrowAlpha + ThrowSpeed * DeltaTime, 0.0, 1.0);

		FHazeRuntimeSpline RuntimeSpline;
		RuntimeSpline.AddPoint(StartLocation);

		if (TargetPlayer != nullptr)
			TargetLocation = TargetPlayer.ActorLocation;

		FVector DirToTarget = (TargetLocation - StartLocation).GetSafeNormal();
		FVector MidPoint = StartLocation + (DirToTarget * StartLocation.Dist2D(TargetLocation)/2);
		MidPoint.Z = MidPoint.Z + ThrowHeight;
		RuntimeSpline.AddPoint(MidPoint);

		RuntimeSpline.AddPoint(TargetLocation);
		RuntimeSpline.SetCustomCurvature(1.0);

		SetActorLocation(RuntimeSpline.GetLocation(ThrowAlpha));
		AddActorLocalRotation(FRotator(45.0, 60.0, 75.0) * 5.0 * DeltaTime);

		if (ThrowAlpha >= 1.0)
			TriggerImpact();
	}

	UFUNCTION()
	void TriggerImpact()
	{
		if (bImpactTriggered)
			return;

		bImpactTriggered = true;

		if (bBeamImpact)
			UVillageThrownBoulderEffectEventHandler::Trigger_BeamImpact(this);
		else
			UVillageThrownBoulderEffectEventHandler::Trigger_Impact(this);

		BP_Impact();
		OnImpact.Broadcast(this);

		if (bDisableOnImpact)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}

class UVillageThrownBoulderEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Thrown() {}
	UFUNCTION(BlueprintEvent)
	void Impact() {}
	UFUNCTION(BlueprintEvent)
	void BeamImpact() {}
}