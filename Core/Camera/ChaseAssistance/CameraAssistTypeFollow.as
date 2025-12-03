
class UCameraFollowAssistSettings : UCameraAssistType
{
	// How fast we rotate
	UPROPERTY()
	float RotationSpeed = 100;

	// At what user movement velocity do we reach alpha 1
	UPROPERTY()
	float MaxUserVelocity = 100;

	/** How much should we be facing the wanted movement direction (0 -> 1)
	 * This is used when the player is moving towards the camera view direction
	 * @Time; 1, we are moving 100% forward in the cameras left/right view direction
	 */
	UPROPERTY()
	FRuntimeFloatCurve ForwardMovementMultiplier;
	default ForwardMovementMultiplier.AddDefaultKey(1, 1);
	default ForwardMovementMultiplier.AddDefaultKey(0, 0);

	/** How much should we be facing the wanted movement direction (0 -> 1)
	 * This is used when the player is moving backwards in the camera view direction
	 * @Time; 1, we are moving 100% forward in the cameras left/right view direction
	 */
	UPROPERTY()
	FRuntimeFloatCurve BackwardMovementMultiplier;
	default BackwardMovementMultiplier.AddDefaultKey(1, 1);
	default BackwardMovementMultiplier.AddDefaultKey(0, 0);


	void Apply(float DeltaTime, float ScriptMultiplier, FCameraAssistSettingsData Settings,
	           FHazeActiveCameraAssistData& Data, FHazeCameraTransform& OutResult) const override
	{
		const FVector ViewRight = Settings.CurrentViewRotation.RightVector;	

		float Multiplier = ScriptMultiplier * Settings.ContextualMultiplier * Settings.InputMultiplier;
		float Sign = Math::Sign(Settings.UserVelocity.DotProduct(ViewRight));
		float VelocityAlpha = Settings.UserVelocity.GetSafeNormal().DotProductLinear(ViewRight);
		Multiplier *= VelocityAlpha;

		float MoveVelocityMultiplier = 1;
		if(MaxUserVelocity > 0)
			MoveVelocityMultiplier = Math::Min(Settings.UserVelocity.Size() / MaxUserVelocity, 1);

		const FVector ViewForward = Settings.CurrentViewRotation.ForwardVector.VectorPlaneProject(Settings.UserWorldUp).GetSafeNormal();	
		const float ForwardDir = Math::Sign(OutResult.UserRotation.ForwardVector.DotProduct(ViewForward));
	
		if(ForwardDir >= 0)
			Multiplier = ForwardMovementMultiplier.GetFloatValue(Multiplier, Multiplier);
		else
			Multiplier = BackwardMovementMultiplier.GetFloatValue(Multiplier, Multiplier);

		const float TargetSpeed = RotationSpeed * Settings.FollowSensitivity * Multiplier * MoveVelocityMultiplier;
		if(Settings.MovementInputRaw.IsNearlyZero())
			Data.YawRotationSpeed.AccelerateTo(0, 0.5, DeltaTime);
		else if(TargetSpeed < Math::Abs(Data.YawRotationSpeed.Value))
			Data.YawRotationSpeed.AccelerateTo(TargetSpeed * Sign, 0.25, DeltaTime);
		else
			Data.YawRotationSpeed.AccelerateTo(TargetSpeed * Sign, 1, DeltaTime);
			
		OutResult.AddLocalDesiredDeltaRotation(FRotator(0, Data.YawRotationSpeed.Value * DeltaTime, 0));
	}
}