struct FGravityBikeFreeTrickActivateParams
{
	EGravityBikeFreeTrick TrickToPerform;
	bool bFlipDirection;
}

struct FGravityBikeFreeTrickDeactivateParams
{
	float Alpha = 0;
	bool bLanded;
	
	bool WasFinished() const
	{
		return Alpha > 1.0 - KINDA_SMALL_NUMBER;
	}
}

enum EGravityBikeFreeTrick
{
	BackFlip,
	AileronRoll,
}

namespace GravityBikeFree
{
	namespace Trick
	{
		const int NumTricks = 2;
	}
}

class UGravityBikeFreeTrickCapability : UHazeCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::TrickTags::GravityBikeFreeTrick);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 70;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeTrickComponent TrickComp;
	UGravityBikeFreeHoverComponent HoverComp;
	UGravityBikeFreeBoostComponent BoostComp;
	UGravityBikeFreeMovementComponent MoveComp;

	AHazePlayerCharacter Player;

	EGravityBikeFreeTrick TrickToPerform;
	bool bFlipDirection;
	FQuat StartRotation;

	float InAirTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		TrickComp = UGravityBikeFreeTrickComponent::Get(GravityBike);
		HoverComp = UGravityBikeFreeHoverComponent::Get(GravityBike);
		BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
		MoveComp = GravityBike.MoveComp;

		Player = GravityBike.GetDriver();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeTrickActivateParams& Params) const
	{
		if(!GravityBike.IsAirborne.Get())
			return false;

		if(!GravityBike.Input.bTappedDrift)
			return false;

		if(GravityBike.IsDrifting())
			return false;

		if(TrickComp.bHasPerformedTrick)
			return false;

		if(InAirTime > GravityBikeFree::Trick::AirTimeWindow)
			return false;

		Params.TrickToPerform = EGravityBikeFreeTrick((int(TrickToPerform) + 1) % GravityBikeFree::Trick::NumTricks);
		Params.bFlipDirection = Math::RandBool();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeTrickDeactivateParams& Params) const
	{
		if(GravityBike.IsDrifting())
			return true;

		if(!MoveComp.IsInAir())
		{
			Params.Alpha = Math::Saturate(ActiveDuration / GravityBikeFree::Trick::Duration);
			Params.bLanded = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(GravityBike.IsAirborne.Get())
		{
			InAirTime += DeltaTime;
		}
		else
		{
			InAirTime = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeTrickActivateParams Params)
	{
		TrickToPerform = Params.TrickToPerform;
		bFlipDirection = Params.bFlipDirection;

		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeHover, this);
		StartRotation = GravityBike.MeshPivot.RelativeRotation.Quaternion();

		if(TrickComp.TrickCamSettings != nullptr)
		    Player.ApplyCameraSettings(TrickComp.TrickCamSettings, 0.2, this, SubPriority = 60);

		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		TrickComp.bIsPerformingTrick = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeTrickDeactivateParams Params)
	{
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeHover, this);

		if(TrickComp.TrickCamSettings != nullptr)
		    Player.ClearCameraSettingsByInstigator(this, 2);

		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		TrickComp.bHasPerformedTrick = true;
		TrickComp.bIsPerformingTrick = false;

		if(Params.Alpha > TrickComp.TrickAlpha)
			TrickComp.TrickAlpha = Params.Alpha;

		if(Params.bLanded)
		{
			BoostComp.SetBoostUntilTime(Time::GameTimeSeconds + (BoostComp.Settings.MaxBoostTime * TrickComp.TrickAlpha));
		}

		TrickComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MeshRotation(DeltaTime);
		//ActorRotation(DeltaTime);
	}

	private void MeshRotation(float DeltaTime)
	{
		float Alpha = ActiveDuration / GravityBikeFree::Trick::Duration;
		FRotator Rotator;

		switch(TrickToPerform)
		{
			case EGravityBikeFreeTrick::BackFlip:
			{
				Alpha = TrickComp.BackFlipCurve.GetFloatValue(Alpha);

				float Angle = bFlipDirection ? TWO_PI : -TWO_PI;
				FQuat Rotation = FQuat(StartRotation.RightVector, Alpha * Angle) * StartRotation;
				Rotator = Rotation.Rotator();
				HoverComp.AccPitch.AccelerateTo(Rotator.Pitch, 0.1, DeltaTime);
				HoverComp.AccRoll.AccelerateTo(Rotator.Roll, 0.1, DeltaTime);
				break;
			}

			case EGravityBikeFreeTrick::AileronRoll:
			{
				Alpha = Math::SmoothStep(0, 1, Alpha);

				float Angle = bFlipDirection ? TWO_PI : -TWO_PI;
				FQuat Rotation = FQuat(StartRotation.ForwardVector, Alpha * Angle) * StartRotation;
				Rotator = Rotation.Rotator();
				HoverComp.AccPitch.AccelerateTo(0, GravityBikeFree::Trick::Duration, DeltaTime);
				HoverComp.AccRoll.AccelerateTo(Rotator.Roll, 0.1, DeltaTime);
				break;
			}
		}

		GravityBike.MeshPivot.SetRelativeRotation(Rotator);
	}

	// private void ActorRotation(float DeltaTime)
	// {
	// 	// Rotate towards camera dir
	// 	float Angle = Math::RadiansToDegrees(GravityBike.ActorForwardVector.AngularDistance(GravityBike.GetCameraDir()));
	// 	if(Angle > GravityBikeFree::KartDrift::RotateToCameraDirAngleCap)
	// 		Angle = GravityBikeFree::KartDrift::RotateToCameraDirAngleCap;

	// 	// if(DriftComp.GetDriftCameraDir().DotProduct(GravityBike.ActorRightVector) > 0)
	// 	// 	Angle = -Angle;

	// 	float AngularSpeed = Angle * GravityBikeFree::KartDrift::RotateToCameraDirSpeed;
	// 	GravityBike.AccSteering.AccelerateTo(GravityBike.Input.Steering, GravityBike.Settings.SteeringDuration, DeltaTime);

	// 	FRotator NewRotation = GravityBike.ActorRotation.Compose(Math::RotatorFromAxisAndAngle(MoveComp.WorldUp, -AngularSpeed * DeltaTime));
	// 	GravityBike.SetActorRotation(NewRotation);
	// }
}