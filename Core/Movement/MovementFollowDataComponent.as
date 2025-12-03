
struct FHazeFollowMovementData
{
	FVector TeleportationDelta = FVector::ZeroVector;
	FVector MovementDelta = FVector::ZeroVector;
	FRotator DeltaRotation = FRotator::ZeroRotator;
}

/**
 * This Component allows us to store how the 
 */
class UCameraFollowMovementFollowDataComponent : UActorComponent
{
	FHazeFollowMovementData CameraFollowMovementData;

	UCameraUserComponent CameraUserComponent;
	
	private TArray<FInstigator> CameraFollowMovementRotationInstigators;
	private uint CameraFollowMovementRotationBlockedFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CameraUserComponent = UCameraUserComponent::Get(Owner);
	}

	void StartApplyMovementRotationToCamera(FInstigator Instigator)
	{
		if(CameraFollowMovementRotationInstigators.AddUnique(Instigator))
		{
			// If this is the first instigator, we need to wait 1 frame
			// until the camera starts follow, else, if we attach the player
			// and the attached rotation is way of from the initial rotation
			// the camera is going to make a hugh turn
			if(CameraFollowMovementRotationInstigators.Num() == 1)
			{
				CameraFollowMovementRotationBlockedFrame = GFrameNumber;
			}
		}
	}

	void StopApplyMovementRotationToCamera(FInstigator Instigator)
	{
		CameraFollowMovementRotationInstigators.RemoveSingleSwap(Instigator);
	}

	void UpdateActorTransformFromFollowMovement(FTransform NewActorTransform, bool bFromRefFrame)
	{
		// Store the information about the follow movement
		// so the camera system can update accordingly.
		// Its important not to include the camera system here, since that will make the compile slow
		{
			// This makes the camera turn when the ground we are following turns.
			if(CameraFollowMovementRotationInstigators.Num() > 0 && CameraFollowMovementRotationBlockedFrame != GFrameNumber)
			{
				// Do big-boy quat instead, awkward bullshit happens otherwise
				FQuat DeltaQuat = NewActorTransform.Rotation.Inverse() * Owner.ActorQuat;

				// Add just the yaw delta.
				// Only valid scenario to move yaw or roll is when gravity is messed with, in which case
				// user should manually move the yaw axis by means of UCameraUserComponent::SetYawAxis().
				FRotator DeltaRotator = FRotator(0, DeltaQuat.Rotator().Yaw, 0);
				CameraFollowMovementData.DeltaRotation -= DeltaRotator;
			}

			FVector DeltaTranslation = NewActorTransform.Location - Owner.ActorLocation;
			
			if(bFromRefFrame)
			{
				// When the player inherits movement, we want the camera to follow the player
				// with the same amount
				CameraFollowMovementData.TeleportationDelta += DeltaTranslation;
			}
			else
			{
				// When the player inherits movement, we want the camera to follow the player
				// with the same amount
				CameraFollowMovementData.MovementDelta += DeltaTranslation;
			}
		}
	}

	void OnReset()
	{
		CameraFollowMovementData = FHazeFollowMovementData();
	}

	void OnPostMovement()
	{
		CameraFollowMovementData = FHazeFollowMovementData();
	}

	TArray<FInstigator> GetActivationInstigators()
	{
		return CameraFollowMovementRotationInstigators;
	}
};