
class ATeenDragonAirJumpVisualizer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UTeenDragonAirJumpVisualizerComponent Visualizer;
	
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SetWorldScale3D(FVector(4.0));
#endif

	default bIsEditorOnlyActor = true;
};

class UTeenDragonAirJumpVisualizerComponent : UHazeEditorRenderedComponent
{
	default RenderShowFlag = EHazeEditorRenderedShowFlag::EditorRendering;

	// Whether the player will do a (grounded) jump first beforehand
	UPROPERTY(EditAnywhere)
	bool bIncludeJump = true;

	// Whether the player will glide down
	UPROPERTY(EditAnywhere)
	bool bIncludeGlide = true;

	// Whether the dragon is already running horizontally when it enters the trajectory
	UPROPERTY(EditAnywhere)
	bool bStartWithHorizontalVelocity = true;

	UPROPERTY(EditAnywhere)
	float TrajectoryDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float TeenDragonGravity = 1500.0;

	UPROPERTY(EditAnywhere)
	float GravityScale = 2.7;

	UPROPERTY(EditAnywhere)
	UTeenDragonAirGlideSettings AirGlideSettings;

	UPROPERTY(EditAnywhere)
	UTeenDragonJumpSettings JumpSettings;

	UPROPERTY(EditAnywhere)
	UTeenDragonMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		if (MovementSettings == nullptr)
			return;
		OutOrigin = WorldLocation;

		float Distance = MovementSettings.AirHorizontalVelocityAccelerationWithInput * TrajectoryDuration * 1.5;
		OutBoxExtent = FVector(Distance);
		OutSphereRadius = Distance;
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		const float GlideHorizontalDeceleration = 1800.0;

		if (MovementSettings == nullptr)
			return;
		FVector StartPosition = WorldLocation;
		FVector ForwardDir = WorldRotation.ForwardVector;
		FVector Position = StartPosition;
		float Time = 0.0;

		float HorizAccelerationTime = MovementSettings.AirHorizontalMaxMoveSpeed / MovementSettings.AirHorizontalVelocityAccelerationWithInput;
		if (bStartWithHorizontalVelocity)
			HorizAccelerationTime = 0.0;

		float ActualGravity = TeenDragonGravity * GravityScale;

		float InitialSpeed = 0.0;
		if (bIncludeJump)
			InitialSpeed += JumpSettings.JumpImpulse;

		float TimeToGlide = InitialSpeed / ActualGravity;
		float TimeToGlideTerminalVelocity = TimeToGlide + (AirGlideSettings.GlideMaxVerticalSpeed / (ActualGravity));
		float TimeToGlideAcceleration = TimeToGlide + (AirGlideSettings.GlideHorizontalMaxMoveSpeed - MovementSettings.AirHorizontalMaxMoveSpeed) / MovementSettings.AirHorizontalVelocityAccelerationWithInput;

		float BoostDuration = GlideHorizontalDeceleration;
		while (Time < TrajectoryDuration)
		{
			FVector NextPosition = StartPosition;

			if (bIncludeGlide)
			{
				if (bIncludeJump)
					NextPosition.Z += JumpSettings.JumpImpulse * Math::Min(Time, TimeToGlide);
				NextPosition.Z -= 0.5 * ActualGravity * Math::Square(Math::Min(Time, TimeToGlide));
				NextPosition.Z -= 0.5 * ActualGravity  * Math::Square(Math::Clamp(Time - TimeToGlide, 0.0, TimeToGlideTerminalVelocity - TimeToGlide));
				NextPosition.Z -= AirGlideSettings.GlideMaxVerticalSpeed * Math::Max(Time - TimeToGlideTerminalVelocity, 0.0);

				float TimeInBoost = Math::Clamp(Time - TimeToGlide, 0.0, BoostDuration);
				NextPosition += ForwardDir * TimeInBoost;
				NextPosition -= ForwardDir * 0.5 * Math::Square(TimeInBoost) * GlideHorizontalDeceleration;

				NextPosition += ForwardDir * Math::Square(Math::Min(Time, HorizAccelerationTime)) * MovementSettings.AirHorizontalVelocityAccelerationWithInput * 0.5;
				NextPosition += ForwardDir * Math::Max(Time - HorizAccelerationTime, 0.0) * MovementSettings.AirHorizontalMaxMoveSpeed;

				NextPosition += ForwardDir * Math::Square(Math::Clamp(Time - TimeToGlide, 0.0, TimeToGlideAcceleration - TimeToGlide)) * MovementSettings.AirHorizontalVelocityAccelerationWithInput * 0.5;
				NextPosition += ForwardDir * Math::Max(Time - TimeToGlideAcceleration, 0.0) * (AirGlideSettings.GlideHorizontalMaxMoveSpeed - MovementSettings.AirHorizontalMaxMoveSpeed);
			}
			else
			{
				if (bIncludeJump)
					NextPosition.Z += JumpSettings.JumpImpulse * Time;
				NextPosition.Z -= 0.5 * ActualGravity * Time * Time;

				NextPosition += ForwardDir * Math::Square(Math::Min(Time, HorizAccelerationTime)) * MovementSettings.AirHorizontalVelocityAccelerationWithInput * 0.5;
				NextPosition += ForwardDir * Math::Max(Time - HorizAccelerationTime, 0.0) * MovementSettings.AirHorizontalMaxMoveSpeed;
			}

			DrawLine(
				Position,
				NextPosition,
				FLinearColor::Red,
				10.0,
			);
			
			Time += 0.1;
			Position = NextPosition;
		}

	}
};