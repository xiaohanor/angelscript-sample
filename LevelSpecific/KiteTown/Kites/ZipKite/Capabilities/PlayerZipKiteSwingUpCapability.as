struct FZipKiteSwingUpDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerZipKiteSwingUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 3;

	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	UZipKitePlayerComponent ZipKitePlayerComp;
	UZipKitePointComponent ZipPoint;

	bool bMoveCompleted = false;
	USceneComponent LandingTargetComp;

	USceneComponent KiteRoot;

	float SwingUpCameraAlpha = 0;
	float SwingUpCameraActiveDuration = 0;
	float EstimatedSwingUpExitDuration = 0;	
	float RopeDelta;
	float EstimatedTime;
	float InitialVelocitySize;
	float MoveDuration;
	float ReleaseForwardOffset;

	bool bSwingUpCameraActive = false;

	FVector ReleaseLocation;
	FVector InitialPlayerLocation;
	FVector InitialRopeLocation;

	FVector KiteRelativeInitialPlayerLocation;
	FVector KiteRelativeReleaseLocation;
	FVector KiteRelativeInitialRopeLocation;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bSwingUpCameraActive)
		{
			if(MoveComp.IsOnWalkableGround() || ZipKitePlayerComp.PlayerKiteData.PlayerState == EZipKitePlayerStates::Inactive)
			{
				SwingUpCameraAlpha = 0;
				bSwingUpCameraActive = false;
				Player.ClearPointOfInterestByInstigator(ZipKitePlayerComp);
			}
			else
			{
				HandleFocusActor(DeltaTime);
			}
		}
	}

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerZipKiteActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (ZipKitePlayerComp.CurrentKite == nullptr)
			return false;

		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::SwingUp)
			return false;
		
		Params.ZipKiteData = ZipKitePlayerComp.PlayerKiteData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FZipKiteSwingUpDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::SwingUp)
			return true;

		if(bMoveCompleted)
		{	
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerZipKiteActivationParams Params)
	{
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
		ZipKitePlayerComp.PlayerKiteData = Params.ZipKiteData;

		MoveDuration = 0;

		bMoveCompleted = false;
		KiteRoot = ZipKitePlayerComp.CurrentKite.KiteHoverRoot;
		LandingTargetComp = ZipKitePlayerComp.CurrentKite.PlayerLandingPointComp;

		/**
		 * Calculate our 3 positions for our janky ass pseudo swing move
		 * Initial Location
		 * Center rope point / Axis we are swinging around
		 * Our release location for when we initiate the "jump to"
		 */
		FVector RopeAttachLocation = ZipKitePlayerComp.GetRopeAttachLocationAtDistance(ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance);
		InitialRopeLocation = RopeAttachLocation;
		KiteRelativeInitialRopeLocation = LandingTargetComp.WorldTransform.InverseTransformPosition(InitialRopeLocation);

		FVector ToTarget = RopeAttachLocation - Player.ActorLocation;
		RopeDelta = ToTarget.Size();
		FVector ToTargetFlattened = ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.GetTangent(0.9).GetSafeNormal().ConstrainToPlane(MoveComp.WorldUp);
		FVector ToTargetConstrained = ToTargetFlattened.ConstrainToPlane(Player.ActorRightVector);
		InitialPlayerLocation = Player.ActorLocation;
		KiteRelativeInitialPlayerLocation = LandingTargetComp.WorldTransform.InverseTransformPosition(InitialPlayerLocation);

		FVector ToTargetHorizontal = ToTarget.ConstrainToPlane(Player.ActorForwardVector);
		ToTargetHorizontal = ToTargetHorizontal.ConstrainToPlane(MoveComp.WorldUp);

		if(ZipKitePlayerComp.PlayerKiteData.CurrentKite.bAllowRopeShorteningOnSwingUp)
			ReleaseForwardOffset =  Math::Min((ZipKitePlayerComp.PlayerKiteData.CurrentKite.PlayerLandingPointComp.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).Size() / 4, RopeDelta);
		else
			ReleaseForwardOffset = RopeDelta;

		ReleaseLocation = RopeAttachLocation - ToTargetHorizontal + (ToTargetConstrained.GetSafeNormal() * ReleaseForwardOffset);
		KiteRelativeReleaseLocation = LandingTargetComp.WorldTransform.InverseTransformPosition(ReleaseLocation);

		InitialVelocitySize = MoveComp.Velocity.Size();
		InitialVelocitySize = Math::Min(InitialVelocitySize, ZipKitePlayerComp.Settings.ZipSwingUpMinimumVelocity);

		EstimatedTime = (ReleaseLocation - Player.ActorLocation).Size() / InitialVelocitySize;
		EstimatedSwingUpExitDuration = (EstimatedTime * 0.85) + ZipKitePlayerComp.Settings.AerialExitMaxDuration;
		bSwingUpCameraActive = true;	

		Player.ApplyCameraSettings(ZipKitePlayerComp.SwingUpCamSettings, 1, ZipKitePlayerComp, EHazeCameraPriority::High);

		UZipKitePlayerEffectEventHandler::Trigger_LaunchUp(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipLaunchUp(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FZipKiteSwingUpDeactivationParams Params)
	{
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);

		if(Params.bMoveCompleted)
		{
			ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::AerialExit;
		}
		else if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::AerialExit)
		{
			ZipKitePlayerComp.PlayerKiteData.ResetData();
			GrappleComp.Grapple.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			MoveDuration += DeltaTime;
			float Alpha = MoveDuration / EstimatedTime;

			if (HasControl())
			{
				FVector LerpedLocation = Math::VLerp(LandingTargetComp.WorldTransform.TransformPosition(KiteRelativeInitialPlayerLocation),
											LandingTargetComp.WorldTransform.TransformPosition(KiteRelativeReleaseLocation),
												FVector(Alpha,Alpha,Alpha));

				FVector NewLocation = LandingTargetComp.WorldTransform.TransformPosition(KiteRelativeInitialRopeLocation)
										+ (LerpedLocation - LandingTargetComp.WorldTransform.TransformPosition(KiteRelativeInitialRopeLocation)).GetSafeNormal() * Math::Lerp(RopeDelta, ReleaseForwardOffset, Alpha);
				FVector FrameDelta = NewLocation - Player.ActorLocation;
				Movement.AddDeltaWithCustomVelocity(FrameDelta, FrameDelta.GetSafeNormal() * InitialVelocitySize);

				float LeftFFIntensity = Math::Lerp(0.2, 0.0, Alpha);
				float RightFFIntensity = Math::Lerp(0.0, 0.2, Alpha);
				Player.SetFrameForceFeedback(LeftFFIntensity, RightFFIntensity, 0.0, 0.0);
			}	
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			//Initiate our jumpto slighty before we hit fully horizontal
			if(Alpha >= 0.85)
			{
				bMoveCompleted = true;
				ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::AerialExit;
			}

			//Blend out the speedeffect over the move transition
			SpeedEffect::RequestSpeedEffect(Player, 1.0 - Alpha, this, EInstigatePriority::High, 1 - (Alpha));

			HandleGrappleCable();
			CalculateAnimData(Alpha);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ZipKites");
		}
	}

	void HandleGrappleCable()
	{
		GrappleComp.Grapple.SetActorLocation(LandingTargetComp.WorldTransform.TransformPosition(KiteRelativeInitialRopeLocation));
	}

	void CalculateAnimData(float Alpha)
	{
		FRotator TetherPlayerRotation = FRotator::MakeFromZY(InitialRopeLocation - Player.ActorLocation, Owner.ActorRightVector);
		FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());
		ZipKitePlayerComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();
		
		if(Alpha < 0.4)
		{
			ZipKitePlayerComp.AnimData.RelativeVelocity.Y = 1500;
			ZipKitePlayerComp.AnimData.MashRate = 1;
		}
		else
		{
			float NewBSVelocity = Math::GetMappedRangeValueClamped(FVector2D(0.4, 0.8), FVector2D(1500, -1500), Alpha);
			ZipKitePlayerComp.AnimData.RelativeVelocity.Y = NewBSVelocity;
			ZipKitePlayerComp.AnimData.MashRate = Math::Lerp(1, 0, Math::GetMappedRangeValueClamped(FVector2D(0.4, 0.85), FVector2D(1, 0), Alpha));
		}
	}

	void HandleFocusActor(float DeltaTime)
	{
		SwingUpCameraActiveDuration += DeltaTime;
		float SwingUpAlpha = SwingUpCameraActiveDuration / EstimatedSwingUpExitDuration;

		float PoIOffset = Math::Lerp(0.0, 2000.0, SwingUpAlpha);
		FVector PoILoc = ZipKitePlayerComp.CurrentKite.ActorLocation + (ZipKitePlayerComp.CurrentKite.KiteRoot.ForwardVector * PoIOffset);
		ZipKitePlayerComp.FocusActor.SetActorLocation(PoILoc);

		float CameraFraction = Math::Lerp(0.0, 1.0, ZipKitePlayerComp.CameraFractionCurve.GetFloatValue(SwingUpAlpha));
		Player.ApplyManualFractionToCameraSettings(CameraFraction, ZipKitePlayerComp);
	}
};