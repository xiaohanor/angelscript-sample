class ASkylineDraggableGrappleLaunch : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UFUNCTION()
	void EffectEvent_OnStartMoving()
	{
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnStopMoving()
	{
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnStopMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitLowAlpha(float HitStrength)
	{
		FSkylineDraggableGrappleLaunchConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnConstrainHitLowAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitHighAlpha(float HitStrength)
	{
		FSkylineDraggableGrappleLaunchConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;		
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnConstrainHitHighAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnGravityWhipGrabbed()
	{
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnGravityWhipGrabbed(this);
	}		

	UFUNCTION()
	void EffectEvent_OnGravityWhipReleased()
	{
		USkylineDraggableGrappleLaunchEventHandler::Trigger_OnGravityWhipReleased(this);
	}	
};