enum EBigHogFartStage
{
	Loading,
	Ripping,
	Clearing,
	Done
}

struct FBigHogFartActivationParams
{
	AHazePlayerCharacter Player;
}

class UBigHogFartCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ABigHog BigHog;
	EBigHogFartStage Stage;

	float LoadingDuration = 2.0;
	float LoadingMaxScale = 0.2;

	float RippingDuration = 3.0;
	float RippingMaxScale = 0.05;

	float ClearingDuration = 1.0;

	float CurrentBoneScale;
	AHazePlayerCharacter PlayerInstigator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BigHog = Cast<ABigHog>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBigHogFartActivationParams& Params) const
	{
		if (!BigHog.IsFarting())
			return false;

		Params.Player = BigHog.PlayerInstigator;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Stage == EBigHogFartStage::Done)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBigHogFartActivationParams Params)
	{
		Stage = EBigHogFartStage::Loading;
		PlayerInstigator = Params.Player;

		CurrentBoneScale = 0.0;

		PlayerInstigator.ActivateCamera(BigHog.Camera, 2.0, this, EHazeCameraPriority::Medium);
		PlayerInstigator.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);

		PlayerInstigator.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerInstigator.BlockCapabilities(CapabilityTags::GameplayAction, this);

		UBigHogEffectEventHandler::Trigger_HitBelly(BigHog);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Online::UnlockAchievement(n"BigGas");

		BigHog.bFarting = false;
		CurrentBoneScale = 0.0;
		BigHog.FartBoneScale = FVector::ZeroVector;

		PlayerInstigator.DeactivateCamera(BigHog.Camera);
		PlayerInstigator.ClearViewSizeOverride(this);

		PlayerInstigator.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerInstigator.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		BigHog.PlayerInstigator = nullptr;

		UBigHogEffectEventHandler::Trigger_StopFarting(BigHog);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Stage == EBigHogFartStage::Loading)
		{
			float StageFraction = Math::Pow(Math::Saturate(ActiveDuration / LoadingDuration), 3);
			CurrentBoneScale = Math::Lerp(0.0, LoadingMaxScale, StageFraction);

			if (StageFraction >= 1.0)
			{
				Stage = EBigHogFartStage::Ripping;

				// Juice
				BigHog.FartVFX.Activate(true);
				UBigHogEffectEventHandler::Trigger_StartFarting(BigHog);
			}
		}
		else
		if (Stage == EBigHogFartStage::Ripping)
		{
			float TargetBoneScale = Math::Sin(ActiveDuration * 1.618 * 40) * 0.15;
			CurrentBoneScale = Math::FInterpTo(CurrentBoneScale, TargetBoneScale, DeltaTime, 10);

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Saturate(Math::Sin(ActiveDuration * 50)) * 0.5;
			FF.RightMotor = Math::Saturate(Math::Cos(ActiveDuration * 50)) * 0.5;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, BigHog.ActorLocation, 3000, 2000, 2.0);

			for (auto Player : Game::Players)
			 	Player.PlayWorldCameraShake(BigHog.CameraShakeClass, this, BigHog.ActorLocation, 3000, 2000, 2.0, 0.8, true);

			float StageFraction = Math::Saturate((ActiveDuration - LoadingDuration) / RippingDuration);
			if (StageFraction >= 1.0)
			{
				Stage = EBigHogFartStage::Clearing;
				BigHog.FartVFX.Deactivate();
			}
		}
		else
		if (Stage == EBigHogFartStage::Clearing)
		{
			float StageFraction = Math::Saturate((ActiveDuration - LoadingDuration - RippingDuration) / ClearingDuration);

			CurrentBoneScale = Math::FInterpTo(CurrentBoneScale, 0.0, DeltaTime, 20);

			if (StageFraction >= 1.0)
				Stage = EBigHogFartStage::Done;
		}

		BigHog.FartBoneScale = FVector(CurrentBoneScale);
	}
}