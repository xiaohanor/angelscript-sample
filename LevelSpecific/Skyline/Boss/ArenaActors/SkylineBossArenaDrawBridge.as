class USkylineBossArenaDrawBridgeCable : UStaticMeshComponent
{
	UPROPERTY(EditInstanceOnly)
	AActor Anchor;

	void Update()
	{
		if (Anchor == nullptr)
			return;

		FVector ToAnchor = Anchor.ActorLocation - WorldLocation;

		ComponentQuat = FQuat::MakeFromZ(ToAnchor);
		WorldScale3D = FVector(WorldScale.X, WorldScale.Y, ToAnchor.Size() * 0.01);
	}
}

class ASkylineBossArenaDrawBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BridgePivot;

	UPROPERTY(EditAnywhere)
	float Angle = 45.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike BridgeAnimation;
	default BridgeAnimation.Duration = 8.0;
	default BridgeAnimation.bCurveUseNormalizedTime = true;
	default BridgeAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default BridgeAnimation.Curve.AddDefaultKey(1.0, 1.0);

	TArray<USkylineBossArenaDrawBridgeCable> Cables;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GetComponentsByClass(Cables);
		
		for (auto Cable : Cables)
		{
			if(Cable == nullptr)
				continue;

			Cable.Update();				
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BridgeAnimation.BindUpdate(this, n"HandleBridgeAnimationUpdate");
		BridgeAnimation.BindFinished(this, n"HandleBridgeAnimationFinished");
	
		GetComponentsByClass(Cables);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Cable : Cables)
		Cable.Update();		
	}

	UFUNCTION()
	void LowerBridge()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		AttachedActors.Add(this);
		for (auto AttachedActor : AttachedActors)
			AttachedActor.RemoveActorDisable(this);

//		BridgeAnimation.Reverse();
	}

	UFUNCTION()
	void RaiseBridge()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		AttachedActors.Add(this);
		for (auto AttachedActor : AttachedActors)
			AttachedActor.AddActorDisable(this);


//		BridgeAnimation.Play();
	}

	UFUNCTION()
	private void HandleBridgeAnimationUpdate(float CurrentValue)
	{
//		for (auto Cable : Cables)
//			Cable.Update();

		BridgePivot.RelativeRotation = FRotator(Angle * CurrentValue, 0.0, 0.0);
	}

	UFUNCTION()
	private void HandleBridgeAnimationFinished()
	{
	}
};