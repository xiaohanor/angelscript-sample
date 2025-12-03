asset TeenTailDragonLandingCameraSettings of UTeenDragonLandingCameraSettings
{
	CameraImpulsePerSpeedIntoLanding = 0.75;
} 

asset TeenAcidDragonLandingCameraSettings of UTeenDragonLandingCameraSettings
{

} 

class UTeenDragonLandingCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonLandingCamera);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTeenDragonComponent DragonComp;
	UPlayerTailTeenDragonComponent TailComp;
	UTeenDragonRollComponent RollComp;
	UTeenDragonRollBounceComponent BounceComp;
	UHazeMovementComponent MoveComp;

	UTeenDragonLandingCameraSettings LandingSettings;

	float TimeLastAppliedLandCameraImpulse;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(MoveComp.HasImpactedGround() && !MoveComp.WasInAir() && DragonComp.bLandingBlockedThisFrame)
			DragonComp.bLandingBlockedThisFrame = false;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		TailComp = UPlayerTailTeenDragonComponent::Get(Player);
		BounceComp = UTeenDragonRollBounceComponent::Get(Player);

		if(Player.IsMio())
			Player.ApplyDefaultSettings(TeenAcidDragonLandingCameraSettings);
		else
			Player.ApplyDefaultSettings(TeenTailDragonLandingCameraSettings);

		LandingSettings = UTeenDragonLandingCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasImpactedGround())
			return false;

		if(!MoveComp.WasInAir())
			return false;

		if(DragonComp.bTopDownMode)
			return false;

		if(TailComp != nullptr && TailComp.IsClimbing())
			return false;

		if(DragonComp.bLandingBlockedThisFrame)
			return false;

		if(MoveComp.PreviousVerticalVelocity.Size() < 50)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlayCameraShake((TailComp != nullptr && RollComp.IsRolling()) ? TailComp.RollingLandCameraShake : DragonComp.LandingCameraShake, this);
		UTeenDragonMovementEffectHandler::Trigger_OnLand(Player);

		FHazeCameraImpulse CameraImpulse;
		float LandingSpeed;
		FVector ImpactNormal = FVector::UpVector;

		LandingSpeed = MoveComp.PreviousVelocity.DotProduct(-MoveComp.CurrentGroundImpactNormal);
		if(Player.IsZoe())
		{
			if(BounceComp.HasResolverBouncedThisFrame())
				LandingSpeed = BounceComp.PreviousBounceData.SpeedIntoGroundNormal;
		}

		LandingSpeed *= LandingSettings.CameraImpulsePerSpeedIntoLanding;
		LandingSpeed = Math::Clamp(LandingSpeed, LandingSettings.CameraImpulseMinSize, LandingSettings.CameraImpulseMaxSize);

		float TimeSinceLastCameraImpulse = Time::GetGameTimeSince(TimeLastAppliedLandCameraImpulse);
		if(TimeSinceLastCameraImpulse < LandingSettings.DelayBeforeFullCameraImpulse)
		{
			float CameraImpulseTimeAlpha = TimeSinceLastCameraImpulse / LandingSettings.DelayBeforeFullCameraImpulse;
			LandingSpeed *= (1 - CameraImpulseTimeAlpha);
		}

		TEMPORAL_LOG(Player, "Dragon Land Impulse")
			.Value("Landing Speed", LandingSpeed)
		;

		CameraImpulse.WorldSpaceImpulse = -ImpactNormal * LandingSpeed;
		CameraImpulse.ExpirationForce = LandingSettings.CameraImpulseExpirationForce;
		CameraImpulse.Dampening = LandingSettings.CameraImpulseDampening;
		Player.ApplyCameraImpulse(CameraImpulse, this);

		TimeLastAppliedLandCameraImpulse = Time::GameTimeSeconds;
	}
}