struct FMoonMarketExitYarnParams
{
	bool bCanForceRoll = false;
}

class UMoonMarketYarnBallPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	AMoonMarketYarnBall YarnBall;
	UMoonMarketYarnBallPotionComponent YarnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UMoonMarketPlayerShapeshiftCapability::Setup();
		YarnComp = UMoonMarketYarnBallPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMoonMarketExitYarnParams& Params) const
	{
		if(YarnBall.GetYarnUnwindedAlpha() == 1)
		{
			Params.bCanForceRoll = true;
			return true;
		}

		if(WasActionStarted(ActionNames::Cancel))
		{
			Params.bCanForceRoll = true;
			return true;
		}

		return UMoonMarketPlayerShapeshiftCapability::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();

		YarnBall = SpawnActor(YarnComp.YarnClass, Player.ActorLocation, bDeferredSpawn = true);
		YarnBall.MakeNetworked(this, ShapeshiftComp.NetId);
		YarnBall.SetActorControlSide(Player);
		YarnBall.ControllingPlayer = Player;
		FinishSpawningActor(YarnBall);
		YarnBall.SetActorLocation(YarnBall.ActorLocation + FVector::UpVector * YarnBall.Collision.ScaledSphereRadius);
		CurrentShape = YarnBall;

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		Player.AttachToActor(YarnBall);

		ShapeshiftComp.Shapeshift(YarnBall, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMoonMarketExitYarnParams Params)
	{
		if(YarnBall.MoveComp.HasGroundContact())
		{
			if(Params.bCanForceRoll)
			{
				if(YarnBall.GetYarnUnwindedAlpha() == 1)
					YarnComp.bForceJump = true;
				else if(YarnBall.ActorHorizontalVelocity.Size() > KINDA_SMALL_NUMBER)
					YarnComp.bForceJump = true;
			}

			Player.SetActorLocation(YarnBall.ActorLocation + FVector::DownVector * YarnBall.Collision.ScaledSphereRadius);
		}
		
		Player.ResetMovement();
		Player.SetActorVelocity(YarnBall.ActorVelocity);
		Player.SetActorRotation(YarnBall.ActorHorizontalVelocity.ToOrientationRotator());


		YarnBall.ControllingPlayer = nullptr;
		YarnBall.Collision.SetSphereRadius(0);
		YarnBall.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		Player.Mesh.RemoveComponentVisualsBlocker(this); 
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(YarnBall.MoveComp.HasGroundContact())
		{
			if(WasActionStarted(ActionNames::MovementJump))
			{
				UMoonMarketYarnBallEventHandler::Trigger_OnBounce(YarnBall);
				YarnBall.AddMovementImpulse(FVector::UpVector * 700);
			}
		}
	}
};