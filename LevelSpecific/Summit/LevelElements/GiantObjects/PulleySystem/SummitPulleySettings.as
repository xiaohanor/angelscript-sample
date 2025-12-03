class USummitPulleySettings : UHazeComposableSettings
{	
	// The speed at which the tail dragon pulls the pulley backwards
	UPROPERTY()
	float PullingBackSpeed = 230;

	// The speed at which the pulley goes forward with input
	UPROPERTY()
	float PullingForwardSpeed = 500;

	// The offset of attachment point when using the pulley
	UPROPERTY()
	float PulleyAttachmentOffset = 200;

	// Time axle ; 0 - 1 how much it's pulled
	// Value axle ; 0 - 1 how much resistance percentage wise it is to pull it  
	UPROPERTY()
	FRuntimeFloatCurve PulleyResistance;
	default PulleyResistance.AddDefaultKey(0, 0.2);
	default PulleyResistance.AddDefaultKey(0.5, 0);
	
	// If it should get stuck at fully pulled, and not spring back
	UPROPERTY()
	bool bShouldStayAtFullyPulled = false;

	// At which threshold of the alpha the pulley acts as it is fully pulled for the bool above
	UPROPERTY()
	float FullyPulledThreshold = 1.0;

	// How much the pulley retracts when the dragon is not pulling it
	UPROPERTY()
	float SpringStrengthWhileNotPulling = 5;

	// How much the pulley retracts while the dragon is pulling it
	UPROPERTY()
	float SpringStrengthWhilePulling = 0;

	// CAMERA
	
	UPROPERTY()
	float CameraBlendInTime = 1.0;

	UPROPERTY()
	float CameraBlendOutTime = 1.0;
	
	// EXIT
	// FOR ANIMATION PURPOSES
	
	// Duration before control is given back to the player after exiting the interaction
	UPROPERTY()
	float NormalExitDuration = 0.5;

	// Threshold at which it is considered a long pull exit 
	UPROPERTY()
	float LongExitFractionThreshold = 0.5;

	// Duration before control is given back to the player after exiting the interaction when the pulley is pulled over the threshold
	UPROPERTY()
	float LongExitDuration = 1.0;
}