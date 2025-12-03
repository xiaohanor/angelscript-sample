
UCLASS(Blueprintable)
class UPrototypeIslandPlatformMoveComp : UActorComponent
{
	default TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(EditAnywhere)
	FTransform OffsetTransform = FTransform::Identity;

	UPROPERTY(EditAnywhere)
	FRotator DeltaRotaiton = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere)
	float MoveAlphaMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	bool bStartPositionIsInTheMiddle = false;

	UPROPERTY(EditAnywhere)
	float RotationAlphaMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	bool bStartRotationIsInTheMiddle = false;

	UPROPERTY(EditAnywhere)
	bool bCauseDesyncInNetwork = false;

	private FTransform StartTransform;
	private FTransform EndTransform;
	private FRotator CurrentBonusRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = Owner.GetActorTransform();
		CurrentBonusRotation = FRotator::ZeroRotator;
	
		EndTransform.SetLocation(StartTransform.Location + OffsetTransform.Location);
		EndTransform.SetRotation(StartTransform.Rotation * OffsetTransform.Rotation);
		EndTransform.SetScale3D(StartTransform.Scale3D * OffsetTransform.Scale3D);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTransform FrameTransform;

		float GameTime = Time::GameTimeSeconds;
		if (!HasControl() && bCauseDesyncInNetwork)
			GameTime += 17.1717;

		float TranslationAlpha = 0.0;
		{
			if(bStartPositionIsInTheMiddle)
				TranslationAlpha = Math::Cos(GameTime) * MoveAlphaMultiplier;
			else
				TranslationAlpha = (Math::Cos(GameTime) + 1.0) * 0.5 * MoveAlphaMultiplier;	
		}

		float RotationAlpha = 0.0;
		{
			if(bStartRotationIsInTheMiddle)
				RotationAlpha = Math::Cos(GameTime) * RotationAlphaMultiplier;
			else
				RotationAlpha = (Math::Cos(GameTime) + 1.0) * 0.5 * RotationAlphaMultiplier;	
		}

		// Location
		FrameTransform.SetLocation(Math::Lerp(StartTransform.Location, EndTransform.Location, TranslationAlpha));

		// Rotation
		CurrentBonusRotation += DeltaRotaiton * DeltaSeconds;
		FRotator LerpedRotation = Math::LerpShortestPath(StartTransform.Rotator(), EndTransform.Rotator(), RotationAlpha);
		LerpedRotation += CurrentBonusRotation;
		FrameTransform.SetRotation(LerpedRotation);

		// Scale
		FrameTransform.SetScale3D(Math::Lerp(StartTransform.Scale3D, EndTransform.Scale3D, TranslationAlpha));

		// Apply values
		Owner.SetActorTransform(FrameTransform);

	}
}