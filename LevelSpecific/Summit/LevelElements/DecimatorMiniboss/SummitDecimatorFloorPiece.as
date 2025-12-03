event void FSummitDecimatorFloorPieceSignature();

class ASummitDecimatorFloorPiece : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent Pivot;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitDecimatorFloorPieceSignature OnActivated;


	UPROPERTY()
	bool bIsPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(DecimatorTopdownTags::PlatformTeamTag);

		StartingTransform = Pivot.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		
		if (bAutoPlay)
			MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void MovePlatform()
	{
		MoveAnimation.Play();
		OnActivated.Broadcast();

	}

	UFUNCTION()
	void LiftPlatform()
	{
		MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		Pivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Pivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

	}

}

namespace DecimatorTopdownTags
{
	const FName PlatformTeamTag = n"PlatformTeam";
}