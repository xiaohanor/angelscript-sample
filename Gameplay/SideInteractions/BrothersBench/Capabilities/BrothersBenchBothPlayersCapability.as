struct FBrothersBenchBothPlayersActivateParams
{
	AHazePlayerCharacter CameraPlayer;
};

class UBrothersBenchBothPlayersCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ABrothersBench BrothersBench;

	AHazePlayerCharacter CameraPlayer;
	FHazeActionQueue ActionQueue;

	TPerPlayer<float> PostProcessWeights;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BrothersBench = Cast<ABrothersBench>(Owner);
		ActionQueue.Initialize(BrothersBench);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBrothersBenchBothPlayersActivateParams& Params) const
	{
		if(!BrothersBench.AreBothPlayersSitting())
			return false;

		// Wait for blend out to fully finish
		if(DeactiveDuration < BrothersBench.BlendOutTime + 0.5)
			return false;

		if(!BrothersBench.GetFirstSittingPlayer(Params.CameraPlayer))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Wait for the projected blend to finish
		if(BrothersBench.BlendState < EBrothersBenchBlendState::ProjectionBlended)
			return false;

		if(!BrothersBench.AreBothPlayersSitting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBrothersBenchBothPlayersActivateParams Params)
	{
		CameraPlayer = Params.CameraPlayer;

		ActionQueue.Event(this, n"StartProjectedBlend");
		ActionQueue.IdleUntil(this, n"WaitForProjectedBlend");
		ActionQueue.Event(this, n"PostProjectedBlend");
		ActionQueue.Event(this, n"StartConversation");
		ActionQueue.Idle(BrothersBench.VistaDelay);
		ActionQueue.Event(this, n"ActivateVistaCamera");
		ActionQueue.Idle(BrothersBench.VistaBlendTime);
		ActionQueue.Event(this, n"OnConversationEnded");

		// Mark the bench as having been sat on, and unlock the achievement if we have collected all benches
		bool bAllBenchesVisited = true;
		Profile::SetProfileValue(Online::PrimaryIdentity, FName(f"Bench.{int(BrothersBench.BenchID)}"), "true");
		for (int i = 0; i < int(EBrothersBenchID::MAX); ++i)
		{
			FString StoredValue;
			bool bHadValue = Profile::GetProfileValue(Online::PrimaryIdentity, FName(f"Bench.{i}"), StoredValue);
			if (!bHadValue || StoredValue != "true")
			{
				bAllBenchesVisited = false;
				break;
			}
		}

		if (bAllBenchesVisited)
		{
			Online::UnlockAchievement(n"FindAllBenches");
		}

		if(!BrothersBench.bHasEndedConversation)
		{
			// While playing the conversation, don't show the cancel prompt
			BrothersBench.LeftInteraction.bShowCancelPrompt = false;
			BrothersBench.RightInteraction.bShowCancelPrompt = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionQueue.Empty();

		if(BrothersBench.BlendState >= EBrothersBenchBlendState::Vista)
		{
			CameraPlayer.DeactivateCameraByInstigator(this, BrothersBench.BlendOutTime);
		}

		if(BrothersBench.BlendState >= EBrothersBenchBlendState::ProjectionBlending)
		{
			Camera::BlendToSplitScreenUsingProjectionOffset(
				this,
				BrothersBench.BlendOutTime
			);
		}

		CameraPlayer = nullptr;
		BrothersBench.BlendState = EBrothersBenchBlendState::None;

		BrothersBench.LeftInteraction.bShowCancelPrompt = true;
		BrothersBench.RightInteraction.bShowCancelPrompt = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActionQueue.Update(DeltaTime);
	}

	UFUNCTION()
	void StartProjectedBlend()
	{
		BrothersBench.BlendState = EBrothersBenchBlendState::ProjectionBlending;

		Camera::BlendToFullScreenUsingProjectionOffset(
			CameraPlayer,
			this,
			BrothersBench.BlendTime,
			BrothersBench.BlendTime
		);
	}

	UFUNCTION()
	private bool WaitForProjectedBlend() const
	{
		auto CameraSingleton = Game::GetSingleton(UCameraSingleton);
		if(CameraSingleton.IsBlendingToFullScreen())
			return false;

		return true;
	}

	UFUNCTION()
	private void PostProjectedBlend()
	{
		BrothersBench.BlendState = EBrothersBenchBlendState::ProjectionBlended;

		if(!BrothersBench.AreBothPlayersSitting())
		{
			// Someone has gotten up! Cancel!
			ActionQueue.Empty();
			return;
		}
	}

	UFUNCTION()
	private void StartConversation()
	{
		BrothersBench.BlendState = EBrothersBenchBlendState::WaitForVista;
		BrothersBench.bStartConversation = true;
	}

	UFUNCTION()
	void ActivateVistaCamera()
	{
		if(!BrothersBench.AreBothPlayersSitting())
		{
			// Cancel!
			BrothersBench.BlendState = EBrothersBenchBlendState::WaitForVista;
			return;
		}

		BrothersBench.BlendState = EBrothersBenchBlendState::Vista;
		CameraPlayer.ActivateCamera(
			BrothersBench.VistaCamera,
			BrothersBench.VistaBlendTime,
			this,
			EHazeCameraPriority::VeryHigh
		);
	}

	UFUNCTION()
	private void OnConversationEnded()
	{
		BrothersBench.LeftInteraction.bShowCancelPrompt = true;
		BrothersBench.RightInteraction.bShowCancelPrompt = true;
	}
};