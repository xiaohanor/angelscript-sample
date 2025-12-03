
UCLASS(Abstract)
class UWorld_Shared_Platform_AmbientMovement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AAmbientMovement MovingActor;

	private FRotator PreviousRotation;
	private FVector PreviousLocation;

	private float CachedRotationSpeed;
	private float CachedRotationDirection = 0.0;

	private float CachedTranslationSpeed = 0.0;
	private float CachedMovementDirection = 0.0;

	#if EDITOR
	private float MaxTrackedBobbingSpeed = 0.0;
	private float MaxTrackedSwingSpeed = 0.0;
	private bool bCanLog = false;
	#endif

	TArray<AHazePlayerCharacter> Players;
	UPrimitiveComponent MultiPositionComp;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MaxBobbingSpeed = 75;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MaxRotationSpeed = 1.5;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MaxSwingSpeed = 1.5;

	UPROPERTY(Category = "Positioning")
	bool bUseMultiPosition = false;
	private TArray<FAkSoundPosition> SoundPositions;

	UPROPERTY(Category = "Positioning")
	FName AttachComponentName = NAME_None;

	private	float PreviousAngle = 0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MovingActor = Cast<AAmbientMovement>(HazeOwner);	

		if(bUseMultiPosition)
			SoundPositions.SetNum(2);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(AttachComponentName != NAME_None)
		{
			TargetActor = MovingActor;
			ComponentName = n"PlatformMesh";
			bUseAttach = true;
			return false;
		}
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IsRotating() || IsSwinging())
		{
			CachedRotationSpeed = MovingActor.ActualMesh.WorldRotation.Quaternion().AngularDistance(PreviousRotation.Quaternion()) / DeltaSeconds;

			if(IsSwinging())
				CachedRotationDirection = Math::Sign(MovingActor.CurrentSwingAngle - PreviousAngle);
			
			PreviousAngle = MovingActor.CurrentSwingAngle;
			PreviousRotation = MovingActor.ActualMesh.WorldRotation;
		}

		if(IsBobbing())
		{
			CachedTranslationSpeed = (MovingActor.ActualMesh.WorldLocation - PreviousLocation).Size() / DeltaSeconds;
			CachedMovementDirection = Math::Sign(MovingActor.ActualMesh.WorldLocation.Z - PreviousLocation.Z);
			PreviousLocation = MovingActor.ActualMesh.WorldLocation;
		}

		if(bUseMultiPosition && AttachComponentName != NAME_None)
		{
			for(auto& Player : Players)
			{
				FVector ClosestPos;
				const float Dist = MultiPositionComp.GetClosestPointOnCollision(Player.ActorLocation, ClosestPos);
				if(Dist < 0)
					ClosestPos = MultiPositionComp.WorldLocation;
				
				SoundPositions[Player.Player].SetPosition(ClosestPos);
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
		}

		#if EDITOR
		if(bCanLog)
		{
			auto TemporalLog = TEMPORAL_LOG(this, "Audio");
			
			if(IsRotating())
			{
				auto Group = TemporalLog.Page("Rotation");
				Group.Value("Rotation Speed: ", CachedRotationSpeed);			
			}

			if(IsSwinging())
			{
				MaxTrackedSwingSpeed = Math::Max(CachedRotationSpeed, MaxTrackedSwingSpeed);

				auto Group = TemporalLog.Page("Swinging");
				Group.Value("Swing Speed: ", CachedRotationSpeed);
				Group.Value("Max Tracked Swing Speed: ", MaxTrackedSwingSpeed);
				Group.Value("Swing Direction Sign: ", CachedRotationDirection);
			}

			if(IsBobbing())
			{			
				MaxTrackedBobbingSpeed = Math::Max(CachedTranslationSpeed, MaxTrackedBobbingSpeed);

				auto Group = TemporalLog.Page("Bobbing");
				Group.Value("Bobbing Speed: ", CachedTranslationSpeed);
				Group.Value("Max Tracked Bobbing Speed: ", MaxTrackedBobbingSpeed);
				Group.Value("Bobbing Direction: ", CachedMovementDirection);
			}
		}

		bCanLog = true;
		#endif
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Rotating"))
	bool IsRotating()
	{
		return MovingActor.RotateSpeed > 0 && !MovingActor.RotateAxis.IsZero();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Swinging"))
	bool IsSwinging()
	{
		return MovingActor.SwingSpeed > 0 && !MovingActor.SwingAxis.IsZero();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Bobbing"))
	bool IsBobbing()
	{
		return MovingActor.BobSpeed > 0 && !MovingActor.BobAxis.IsZero();
	}

	UFUNCTION(BlueprintPure)
	void GetRotationSpeed(float&out Speed, float&out Direction, float&out Alpha)
	{
		if(!IsRotating() && !IsSwinging())
			return;

		Speed = Math::Min(1.0, CachedRotationSpeed / MaxRotationSpeed);
		Direction = CachedRotationDirection;

		const float RotationDistanceFromCenter = MovingActor.ActualMesh.WorldRotation.Quaternion().AngularDistance(Math::RotatorFromAxisAndAngle(MovingActor.SwingAxis, MovingActor.SwingAngle).Quaternion());

																			// TODO: I don't know why this is the magic number, but it seems to work in all cases?
		Alpha = Math::Lerp(0.0, 1.0, Math::GetPercentageBetweenClamped(0.0, 1.58, RotationDistanceFromCenter));
		//Alpha *= Math::Sign(MovingActor.ActualMesh.WorldRotation.Z - MovingActor.ActorLocation.Z);
	}

	UFUNCTION(BlueprintPure)
	void GetBobbingSpeed(float&out Speed, float&out Direction, float&out Alpha)
	{
		if(!IsBobbing())
			return;

		Speed = Math::Min(1.0, CachedTranslationSpeed / MaxBobbingSpeed);
		Direction = CachedMovementDirection;
		Alpha = MovingActor.ActualMesh.WorldLocation.Distance(MovingActor.ActorLocation) / (MovingActor.BobAxis.Size() * MovingActor.BobDistance);
		Alpha *= Math::Sign(MovingActor.ActualMesh.WorldLocation.Z - MovingActor.ActorLocation.Z);
	}
}