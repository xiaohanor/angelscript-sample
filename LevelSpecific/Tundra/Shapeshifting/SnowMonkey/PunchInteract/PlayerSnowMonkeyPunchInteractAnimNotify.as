class UTundraPlayerSnowMonkeyPunchInteractAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyPunchInteract";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp == nullptr)
			return false;

		auto Monkey = Cast<ATundraPlayerSnowMonkeyActor>(MeshComp.Owner);
		auto Player = Cast<AHazePlayerCharacter>(Monkey.AttachParentActor);
		if(Player == nullptr)
			return false;

		auto MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		if(MonkeyComp.CurrentPunchInteractAnimationType != ETundraPlayerSnowMonkeyPunchInteractAnimationType::None)
		{
			FVector LeftLocation = Monkey.Mesh.GetSocketLocation(n"LeftAttach");
			FVector RightLocation = Monkey.Mesh.GetSocketLocation(n"RightAttach");
			FVector RelativeLeftLocation = Monkey.Mesh.WorldTransform.InverseTransformPosition(LeftLocation);
			FVector RelativeRightLocation = Monkey.Mesh.WorldTransform.InverseTransformPosition(RightLocation);

			FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
			Trace.UseLine();
			Trace.IgnorePlayers();
			Trace.SetReturnPhysMaterial(true);
			FVector Origin = Player.ActorLocation + FVector::UpVector * 220.0;
			FHitResult Hit = Trace.QueryTraceSingle(Origin, Origin + Player.ActorForwardVector * 500.0);

			FTundraPlayerSnowMonkeyPunchInteractEffectParams EffectParams;
			EffectParams.PhysMat = Hit.PhysMaterial;
			if(RelativeRightLocation.X < RelativeLeftLocation.X)
				EffectParams.PunchHandLocation = LeftLocation;
			else
				EffectParams.PunchHandLocation = RightLocation;

			// Debug::DrawDebugSphere(EffectParams.PunchHandLocation, 20.0, LineColor = FLinearColor::Red, Duration = 2.0);
				
			if(MonkeyComp.CurrentPunchInteractAnimationType == ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi)
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnPunchInteractMultiPunch(Monkey, EffectParams);
			else
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnPunchInteractSinglePunch(Monkey, EffectParams);
		}
		
		MonkeyComp.NotifyPunchTargetableComponent();
		return true;
	}
}