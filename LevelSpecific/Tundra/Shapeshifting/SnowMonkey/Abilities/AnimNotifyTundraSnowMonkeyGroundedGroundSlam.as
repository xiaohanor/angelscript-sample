class UAnimNotifyTundraSnowMonkeyGroundedGroundSlam : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraSnowMonkeyGroundSlam";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		ATundraPlayerSnowMonkeyActor SnowMonkey = Cast<ATundraPlayerSnowMonkeyActor>(MeshComp.GetOwner());
		if(SnowMonkey == nullptr)
		{
			Print("WARNING: Grounded ground slam anim notify not triggered, snow monkey was null!");
			return false;
		}
		AHazePlayerCharacter Player = SnowMonkey.Player;
		if(Player == nullptr)
		{
			Print("WARNING: Grounded ground slam anim notify not triggered, player was null!");
			return false;
		}

		UTundraPlayerSnowMonkeyComponent SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		if(SnowMonkeyComp == nullptr)
		{
			Print("WARNING: Grounded ground slam anim notify not triggered, snow monkey comp was null!");
			return false;
		}

		if(!SnowMonkeyComp.bCanTriggerGroundedGroundSlam)
			return false;

		SnowMonkeyComp.GroundSlamZoe();

		TArray<UTundraPlayerSnowMonkeyGroundSlamResponseComponent> ResponseComponents;
		SnowMonkeyComp.NotifyGroundSlamResponseComponent(ETundraPlayerSnowMonkeyGroundSlamType::Grounded, ResponseComponents);

		bool bShouldPlayEffect = true;

		for(auto Response : ResponseComponents)
		{
			if(!Response.bWithGroundSlamEffect)
			{
				bShouldPlayEffect = false;
				break;
			}
		}

		if(bShouldPlayEffect)
		{
			FTundraPlayerSnowMonkeyGroundSlamEffectParams Params;
			Params.bIsInSidescroller = Player.IsPlayerMovementLockedToSpline();
			if (SnowMonkeyComp.IsFarAwayInView())
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundedGroundSlamFarFromView(SnowMonkeyComp.SnowMonkeyActor, Params);
			else
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundedGroundSlam(SnowMonkeyComp.SnowMonkeyActor, Params);
		}

		SnowMonkeyComp.bGroundedGroundSlamHandsHitGround = true;
		SnowMonkeyComp.TimeOfGroundSlamHandsHitGround = Time::GetGameTimeSeconds();
		return true;
	}
}