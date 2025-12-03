
class UGravityBladeGrappleCameraBlend : UHazeCameraViewPointBlendType
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade")
	UCurveFloat TranslationCurve;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade")
	UCurveFloat RotationCurve;


	UFUNCTION(BlueprintOverride)
	bool BlendView(
		FHazeViewBlendInfo& SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeViewBlendInfo& OutCurrentView,
		FHazeCameraViewPointBlendInfo BlendInfo,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		const float BlendFraction = GetBlendAlpha(BlendInfo);
		OutCurrentView = SourceView.Blend(TargetView, BlendFraction);

		if(TranslationCurve != nullptr)
		{
			float TranslationAlpha = Math::Clamp(TranslationCurve.GetFloatValue(BlendFraction), 0, 1);
			OutCurrentView.Location = Math::Lerp(SourceView.Location, TargetView.Location, TranslationAlpha);
		}
	
		if(RotationCurve != nullptr)
		{
			float RotationAlpha = Math::Clamp(RotationCurve.GetFloatValue(BlendFraction), 0, 1);
			OutCurrentView.Rotation = Math::LerpShortestPath(SourceView.Rotation, TargetView.Rotation, RotationAlpha);
		}

		// Debug
		#if !RELEASE
		auto TemporalLog = GetCameraTemporalLog();
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Type", this);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Target Time", BlendInfo.BlendTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Alpha", f"{BlendFraction :.3}");
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Location", OutCurrentView.Location);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Rotation", OutCurrentView.Rotation);
		#endif

		// We need to blend in the entire camera before we finish
		return BlendFraction < 1 - KINDA_SMALL_NUMBER;
	}

	private float GetBlendAlpha(FHazeCameraViewPointBlendInfo BlendInfo) const
	{	
		// Tweak the alpha here
		return Math::EaseInOut(0, 1, BlendInfo.BlendAlpha, 1.5);
	}
}

struct FGravityBladeGrappleCameraCapabilityActivationParams
{
	FVector CameraRightVector = FVector::ZeroVector;
}

class UGravityBladeGrappleCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeCamera);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleCamera);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 101;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;

	UCameraUserComponent CameraUser;
	UCameraSettings CameraSettings;

	float Timer;
	float BlendTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		
		CameraUser = UCameraUserComponent::Get(Owner);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeGrappleCameraCapabilityActivationParams& ActivationParams) const
	{
		if (!GrappleComp.ActiveGrappleData.IsValid())
			return false;

		if (!GrappleComp.ActiveGrappleData.CanShiftGravity())
			return false;

		if (!CameraUser.IsUsingDefaultCamera())
			return false;

		// TODO: Quick & dirty way to activate on pull
		if (!GrappleComp.AnimationData.GrapplePulledThisFrame())
			return false;

		ActivationParams.CameraRightVector = CameraUser.CalculateBaseRotationFromYawAxis(GrappleComp.ActiveGrappleData.WorldUp).RightVector;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Timer >= BlendTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityBladeGrappleCameraCapabilityActivationParams& ActivationParams)
	{
		// We don't align with the world up since that is interpolated and we
		// want the blend to interpolate internally.
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		FRotator TargetViewRotation = Player.GetUnmodifiedViewInfo().Rotation;

		if (GrappleComp.ActiveGrappleData.ShiftComponent != nullptr
			&& GrappleComp.ActiveGrappleData.ShiftComponent.bForceCameraForward)
		{
			FVector ShiftRight = GrappleComp.ActiveGrappleData.ShiftComponent.CameraTargetForward;
			auto ShiftOwner = GrappleComp.ActiveGrappleData.ShiftComponent.Owner;

			TargetViewRotation = FRotator::MakeFromZX(
				GrappleComp.ActiveGrappleData.WorldUp,
				ShiftOwner.ActorTransform.TransformVectorNoScale(ShiftRight),
				);
		}

		Timer = 0.0;
		BlendTime = Math::Max(GrappleComp.GrapplePullDuration + GravityBladeGrapple::LandDuration, GravityBladeGrapple::MinCameraInterpDuration);

		// Lock the view in the current transform and blend it back in using the
		// 'GravityBladeGrappleCameraBlend'
		Player.ApplyBlendToCurrentView(BlendTime, GrappleComp.GrappleCameraBlend);

		// Snap the yaw axis for the camera with the ground we are going to end up on
		// so the blend can rotate in a controlled way
		FVector PendingCameraUp = GrappleComp.ActiveGrappleData.WorldUp;
		CameraUser.SetYawAxis(PendingCameraUp, this, ActivationParams.CameraRightVector);

		// The yaw axis change will flip the rotation
		// So set it back to where we used to face
		CameraUser.SetDesiredRotation(TargetViewRotation, this);

		// No steering during the grapple
		CameraSettings.SensitivityFactor.Apply(0.0, this, SubPriority = 62);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.DeactivateCameraByInstigator(this, 0.0);
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We need the last tick to happen for alphas to hit upper bounds
		// checking ActiveDuration in ShouldDeactivate is a no go; here we are
		Timer = ActiveDuration;

		// Update camera yaw axis since target can change rotation as we grapple
		FVector PendingCameraUp = GrappleComp.ActiveGrappleData.WorldUp;
		CameraUser.SetYawAxis(PendingCameraUp, this);
	}
}
