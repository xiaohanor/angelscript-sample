class UTeenDragonFireBreathComponent : UActorComponent
{
	bool bIsBreathingFire = false;
	bool bHasBeenOnFireSinceLastFireJump = false;
	float LastTimeFireJumped = -MAX_flt;
};