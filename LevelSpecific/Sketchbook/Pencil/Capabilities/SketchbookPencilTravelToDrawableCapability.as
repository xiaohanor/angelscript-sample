struct FSketchbookPencilTravelToDrawableActivateParams
{
	FSketchbookPencilRequest NextRequest;
}

struct FSketchbookPencilTravelToDrawableDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilTravelToDrawableCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 200;

	ASketchbookPencil Pencil;

	bool bHasReachedLocation = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilTravelToDrawableActivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return false;

		if(Pencil.CurrentRequest.IsSet())
			return false;

		if(!Pencil.HasValidRequestInQueue())
			return false;

		// Pop the next request, making it our current target
		const FSketchbookPencilRequest NextRequest = Pencil.GetNextValidRequestInQueue();
		Params.NextRequest = NextRequest;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilTravelToDrawableDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.TravelToRequest.IsSet())
			return true;

		if(Pencil.TravelToRequest.Value.WasInterrupted())
			return true;

		if(!Pencil.TravelToRequest.Value.bErase && Pencil.TravelToRequest.Value.Drawable.IsA(USketchbookDrawableSentenceComponent))
		{
			if(Sketchbook::GetNarrator().IsPlayingVox())
			{
				auto Word = Cast<ASketchbookSentence>(Pencil.TravelToRequest.Value.Drawable.Owner);

				// Wait for narrator to finish before ending!
				if(Word.VoxAsset != nullptr)
				{
					PrintToScreenScaled("Waiting for vox to finish before finishing travel...", 0, FLinearColor::Yellow, 1.5);
					return false;
				}
			}
		}

		// Wait for the pivot to finish transitioning
		if(Pencil.GetPivotState() == ESketchbookPencilPivotState::Transitioning)
		{
			PrintToScreenScaled("Waiting for pivot transition to finish before finishing travel...", 0, FLinearColor::Yellow, 1.5);
			return false;
		}

		if(Pencil.CurrentRequest.IsSet())
			return true;

		if(!Pencil.HasValidRequestInQueue())
			return true;

		if(bHasReachedLocation)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilTravelToDrawableActivateParams Params)
	{
		Pencil.TravelToRequest.Set(Params.NextRequest);
		
		if(HasControl())
		{
			// Make sure that the next request is valid
			Pencil.TrimInvalidRequestsFromStartOfQueue();
		}

		// Start traveling to it
		Pencil.TravelToRequest.Value.Drawable.PrepareTravelTo(Pencil.TravelToRequest.Value.bErase, Pencil.ActorLocation);
		bHasReachedLocation = false;

		USketchbookPencilEventHandler::Trigger_OnMoveTowardsNextDrawable(Pencil);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilTravelToDrawableDeactivateParams Params)
	{
		if(HasControl() && Params.bFinished)
		{
			check(!Pencil.CurrentRequest.IsSet());
			Pencil.PopNextRequestFromQueue();

			// We have reached the target drawable
			// Make it our current request
			Pencil.CurrentRequest.Set(Pencil.TravelToRequest.Value);
		}

		// Force trigger end of movement if it wasn't handled in tick
		if(!Params.bFinished)
			USketchbookPencilEventHandler::Trigger_OnReachedNextDrawable(Pencil);

		Pencil.TravelToRequest.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasReachedLocation)
		{
			FVector TargetLocation = Sketchbook::ProjectWorldLocationToPagePlane(Pencil.TravelToRequest.Value.Drawable.GetTravelToLocation(Pencil.TravelToRequest.Value.bErase));
			Pencil.MoveAccelerateTo(TargetLocation, Pencil.TravelToRequest.Value.Drawable.TravelDuration, DeltaTime, this);
			Pencil.MoveTipOffsetAccelerateTo(Sketchbook::Sentence::TravelToNextWordOffset, Pencil.TravelToRequest.Value.Drawable.TravelDuration, DeltaTime, this);
			
			if(!bHasReachedLocation && Pencil.GetPencilLocation().Equals(TargetLocation, 25.0))
			{
				USketchbookPencilEventHandler::Trigger_OnReachedNextDrawable(Pencil);
				bHasReachedLocation = true;
			}

#if !RELEASE
			TEMPORAL_LOG(this).Point("Target Location", TargetLocation, 1);
#endif
		}
		else
		{
			// Some offset to frame it better
			FVector TipOffset = Sketchbook::Sentence::TravelToNextWordOffset;

			// Add some perlin noise to it
			const float Time = Time::GameTimeSeconds;
			TipOffset += FVector(
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.X) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.X,
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Y) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Y,
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Z) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Z
			);

			Pencil.MoveTipOffsetAccelerateTo(TipOffset, 0.5, DeltaTime, this);

			FRotator TipRotationOffset = FRotator::ZeroRotator;
			TipRotationOffset += FRotator(
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Pitch) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Pitch,
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Yaw) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Yaw,
				Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Roll) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Roll
			);

			Pencil.RotateTipOffsetTowards(TipRotationOffset, 0.4, DeltaTime, this);
		}
	}
};