struct FLightSeekerReturnPathData
{
	FVector StartLocation;
	FVector TargetLocation;
	float InterpolationMoveSpeedPerSecond = 0.0;
	float InterpolationMovementProgress = 1.0;
}

class ULightSeekerReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerReturn");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ALightSeeker LightSeeker;
	ULightSeekerTargetingComponent TargetingComp;
	TArray<FLightSeekerReturnPathData> ReturnPath;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TargetingComp.HasActiveLightBirdTarget())
			return false;

		if (LightSeeker.HasReturned())
			return false;

		if (!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TargetingComp.HasActiveLightBirdTarget())
			return true;

		if (LightSeeker.HasReturned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightSeeker.bIsReturning = true;

		//TargetingComp.DesiredHeadRotation = LightSeeker.Origin.WorldRotation.Quaternion();
		ReturnPath.Empty();

		if (LightSeeker.Head.RelativeLocation.Size() < LightSeeker.DistanceToBeStraightToBurrow)
		{
			AddPathData(LightSeeker.Head.WorldLocation, LightSeeker.StartHeadWorldLocation);
		}
		else
		{
			FVector StraightToBurrowLocation = LightSeeker.Origin.WorldLocation + LightSeeker.Origin.WorldRotation.ForwardVector * LightSeeker.DistanceToBeStraightToBurrow;
			// PrintToScreen("Return " + StraightToBurrowLocation, 5.0);
			AddPathData(LightSeeker.Head.WorldLocation, StraightToBurrowLocation);
			AddPathData(StraightToBurrowLocation, LightSeeker.StartHeadWorldLocation);
		}

		ULightSeekerEventHandler::Trigger_StopChasingLight(LightSeeker);
	}

	private void AddPathData(FVector Start, FVector End)
	{
		FLightSeekerReturnPathData PathData;

		PathData.StartLocation = Start;
		PathData.TargetLocation = End;

		float TotalDistance = (PathData.TargetLocation - PathData.StartLocation).Size();
		PathData.InterpolationMovementProgress = 1.0;
		if (TotalDistance > SMALL_NUMBER)
		{
			PathData.InterpolationMovementProgress = 0.0;
			PathData.InterpolationMoveSpeedPerSecond = LightSeeker.ReturnSpeed / TotalDistance;
		}

		ReturnPath.Add(PathData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightSeeker.bIsReturning = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LightSeeker.bDebugging)
			PrintToScreen("Returning", 0.0, FLinearColor::Green);

		if (ReturnPath.Num() > 0)
		{
			FLightSeekerReturnPathData& PathData = ReturnPath[0];
			if (PathData.InterpolationMovementProgress < 1.0 - SMALL_NUMBER)
			{
				PathData.InterpolationMovementProgress += PathData.InterpolationMoveSpeedPerSecond * DeltaTime;
				PathData.InterpolationMovementProgress = Math::Clamp(PathData.InterpolationMovementProgress, 0.0, 1.0);
				FVector InterpolatedPosition = Math::Lerp(PathData.StartLocation, PathData.TargetLocation, PathData.InterpolationMovementProgress);
				TargetingComp.SyncedDesiredHeadLocation.SetValue(InterpolatedPosition);

				FVector TargetToCurrent = PathData.StartLocation - PathData.TargetLocation;
				TargetingComp.SyncedDesiredHeadRotation.SetValue(FRotator::MakeFromXZ(TargetToCurrent.GetSafeNormal(), LightSeeker.Origin.UpVector));
				if (LightSeeker.bDebugging)
				{
					Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, InterpolatedPosition, FLinearColor::Blue, 2.0, 0.0);
					PrintToScreen("Returning Move Progress " + PathData.InterpolationMovementProgress, 0.0, FLinearColor::Green);
				}
			}
			if (PathData.InterpolationMovementProgress >= 1.0 - SMALL_NUMBER)
			{
				ReturnPath.RemoveAt(0);
			}
		}
		else 
		{
			TargetingComp.SyncedDesiredHeadLocation.SetValue(LightSeeker.Origin.WorldLocation);
			TargetingComp.SyncedDesiredHeadRotation.SetValue(LightSeeker.Origin.WorldRotation);
		}
	}
};