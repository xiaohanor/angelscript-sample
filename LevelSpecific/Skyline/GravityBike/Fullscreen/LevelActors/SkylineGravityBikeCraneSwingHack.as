event void FOnGravityBikeCraneSwingGrabbed();

class ASkylineGravityBikeCraneSwingHack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopePivotTargetRotationComp;

	UPROPERTY(DefaultComponent, Attach = RopePivotTargetRotationComp)
	USceneComponent RopePivotComp;

	UPROPERTY(DefaultComponent, Attach = RopePivotComp)
	USceneComponent WhipAttachmentLocationComp;

	UPROPERTY(DefaultComponent, Attach = RopePivotComp)
	UStaticMeshComponent BikeMeshComp;
	default BikeMeshComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = RopePivotComp)
	UStaticMeshComponent RopeMeshComp;

	UPROPERTY(DefaultComponent, Attach = WhipAttachmentLocationComp)
	UGravityBikeWhipGrabTargetComponent WhipTargetComp;



	UPROPERTY(EditInstanceOnly)
	FRotator TargetRotation;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike BikeLerpToLocationTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike SwingTimeLike;

	UPROPERTY()
	FOnGravityBikeCraneSwingGrabbed OnSwingGrabbed;

	FVector BikeStartLocation;
	
	FRotator BikeStartRotation;

	FRotator SwingStartRotation;

	FRotator RopeRelativeStartRotation;

	bool bGrabbed = false;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BikeLerpToLocationTimeLike.BindUpdate(this, n"BikeLerpToLocationTimeLikeUpdate");
		SwingTimeLike.BindUpdate(this, n"SwingTimeLikeUpdate");
		WhipTargetComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityBikeWhipComponent WhipComp, UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		BikeStartLocation = GravityBikeSpline::GetGravityBike().SkeletalMesh.WorldLocation;
		BikeStartRotation = GravityBikeSpline::GetGravityBike().SkeletalMesh.WorldRotation;
		SwingStartRotation = (BikeStartLocation - RopePivotComp.WorldLocation).Rotation();

		RopePivotTargetRotationComp.SetWorldRotation(SwingStartRotation);
		RopePivotComp.SetWorldRotation(ActorRotation);

		RopeRelativeStartRotation = RopePivotComp.RelativeRotation;

		BikeMeshComp.SetHiddenInGame(false);

		bGrabbed = true;

		SwingTimeLike.PlayFromStart();
		BikeLerpToLocationTimeLike.PlayFromStart();

		OnSwingGrabbed.Broadcast();
	}

	UFUNCTION()
	private void SwingTimeLikeUpdate(float CurrentValue)
	{
		FRotator LerpRotation = Math::LerpShortestPath(SwingStartRotation, TargetRotation + ActorRotation, CurrentValue * 1.5);

		RopePivotTargetRotationComp.SetWorldRotation(LerpRotation);
	}

	UFUNCTION()
	private void BikeLerpToLocationTimeLikeUpdate(float CurrentValue)
	{
		FVector LerpBikeLocation = Math::Lerp(BikeStartLocation, WhipAttachmentLocationComp.WorldLocation, CurrentValue);
		FRotator LerpBikeRotation = Math::LerpShortestPath(BikeStartRotation, WhipAttachmentLocationComp.WorldRotation, CurrentValue);
		FRotator LerpRopeRotation = Math::LerpShortestPath(RopeRelativeStartRotation, FRotator(0.0), CurrentValue);

		BikeMeshComp.SetWorldLocationAndRotation(LerpBikeLocation, LerpBikeRotation);
		RopePivotComp.SetRelativeRotation(LerpRopeRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bGrabbed)
		{
			Debug::DrawDebugLine(BikeMeshComp.WorldLocation, WhipTargetComp.WorldLocation, FLinearColor::LucBlue, 10.0);
		}
	}
};