/*
	TC: Wraps some nice functionality for accelerating desired rotation to a target
	Allows the interruption of this acceleration by camera input
	Includes delays and a scaled interp so it smoothly eases in the acceleration after the delay
*/

struct FAcceleratedInputInterruptedDesiredRotation
{
	protected FHazeAcceleratedRotator AcceleratedDesiredRotation;

	// How long before the camera acceleration interps back in
	float PostInputCooldown = 2.0;
	/*
		Interp speed for acceleration scale once the cooldown has finished.
		1 = 1 second
		2 = 0.5 seconds
	*/
	float PostCooldownInputScaleInterp = 0.5;
	// How fast the camera acceleration is at full speed
	float AcceleratedDuration = 1.0;
	
	protected float CooldownDuration = 0.0;
	protected float InputScale = 1.0;

	// Accelerates and returns the new value
	FRotator Update(FRotator CurrentDesiredRotation, FRotator TargetDesiredRotation, FVector2D CameraStickInput, float DeltaTime)
	{
		if (CameraStickInput.IsNearlyZero())
		{
			if (CooldownDuration < PostInputCooldown)
				CooldownDuration += DeltaTime;
			else
				InputScale = Math::FInterpConstantTo(InputScale, 1.0, DeltaTime, PostCooldownInputScaleInterp);
		}
		else
		{
			CooldownDuration = 0.0;
			InputScale = 0.0;
		}

		AcceleratedDesiredRotation.Value = CurrentDesiredRotation;
		AcceleratedDesiredRotation.AccelerateTo(TargetDesiredRotation, AcceleratedDuration, DeltaTime * InputScale);
		return AcceleratedDesiredRotation.Value;
	}

	// Snap the camera to the current rotation of the camera:  UCameraComponent::WorldRotation
	void Activate(FRotator CurrentCameraRotation)
	{
		AcceleratedDesiredRotation.SnapTo(CurrentCameraRotation);
		InputScale = 1.0;
		CooldownDuration = PostInputCooldown;
	}

	FRotator GetDesiredRotation()
	{
		return AcceleratedDesiredRotation.Value;
	}
}