
UCLASS(Abstract)
class UWorld_Summit_TreasureTemple_Interactable_TailDragonWheel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSmashedThroughGate(FSummitStoneWaterWheelOnSmashedThroughGateParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLanded(){}

	UFUNCTION(BlueprintEvent)
	void OnWheelActivated(){}

	/* END OF AUTO-GENERATED CODE */

	ASummitStoneWaterWheel Wheel;
	UPrimitiveComponent CollisionComp;

	const float MAX_TRACKED_WHEEL_SPEED = 1500;

	UFUNCTION(BlueprintEvent)
	void OnHitConstraintCollider() {};

	UFUNCTION(BlueprintEvent)
	void OnWheelHitCrashTrigger() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Wheel = Cast<ASummitStoneWaterWheel>(HazeOwner);
		CollisionComp = UPrimitiveComponent::Get(Wheel, n"CapsuleComp");

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CollisionComp.OnComponentHit.AddUFunction(this, n"OnWheelColliderHit");
		Wheel.CliffCrashAudioTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnHitCrashTrigger");
	}

	UFUNCTION()
	void OnWheelColliderHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in Hit)
	{
		AStaticMeshActor HitMeshActor = Cast<AStaticMeshActor>(OtherActor);
		if(HitMeshActor == nullptr)
			return;

		OnHitConstraintCollider();
	}

	UFUNCTION()
	void OnHitCrashTrigger(AActor OverlappedActor, AActor OtherActor)
	{
		OnWheelHitCrashTrigger();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Wheel Rotation Speed"))
	float GetWheelRotationSpeed()
	{
		return Math::Min(1, Wheel.MoveComp.Velocity.Size() / MAX_TRACKED_WHEEL_SPEED);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector2D PreviousScreenPosition;
		float PanningRTPC = 0.0;
		float _Y;

		Audio::GetScreenPositionRelativePanningValue(Wheel.WheelMesh.WorldLocation, PreviousScreenPosition, PanningRTPC, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningRTPC, 0.0);
	}

}