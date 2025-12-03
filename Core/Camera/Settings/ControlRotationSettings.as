class UControlRotationSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bOverrideControlRotation = false;

	/**
	 * OBS! Requires 'bOverrideControlRotation'
	 */
	UPROPERTY()
	FRotator ControlRotationOverride;

	/** How fast we should reach the control rotation 
	 * only used if >= 0
	 * if 0, the control rotation don't change at all
	 * OBS! (only applied if 'bOverrideControlRotation' is false) 
	*/
	UPROPERTY()
	float ControlRotationInterpSpeed = -1;
};
