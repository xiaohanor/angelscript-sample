class AGrappleWallrunRespawnPoint : ARespawnPoint
{
	//Which GrappleWallRunPoint should we respawn from
	UPROPERTY(EditInstanceOnly, Category = "Respawn Point")
	AGrappleWallrunPoint LinkedWallrunPoint;

	//Which direction should we wallrun (Based on forward being towards the wall)
	UPROPERTY(EditInstanceOnly, Category = "Respawn Point")
	ELeftRight WallrunDirection;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(LinkedWallrunPoint != nullptr)
		{
			if(WallrunDirection == ELeftRight::Left)
			{
				UGrappleWallrunPointComponent GrapplePointComp = UGrappleWallrunPointComponent::Get(LinkedWallrunPoint);
				SetActorRotation(FRotator::MakeFromXZ(-GrapplePointComp.RightVector, ActorUpVector));
			}
			else
			{
				UGrappleWallrunPointComponent GrapplePointComp = UGrappleWallrunPointComponent::Get(LinkedWallrunPoint);
				SetActorRotation(FRotator::MakeFromXZ(GrapplePointComp.RightVector, ActorUpVector));
			}
		}
	}

	FTransform GetPositionForPlayer(AHazePlayerCharacter Player)const override
	{
		return FTransform::Identity * Root.WorldTransform;
	}

	FTransform GetRelativePositionForPlayer(AHazePlayerCharacter Player)const override
	{
		return FTransform::Identity;
	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		if(LinkedWallrunPoint != nullptr)
		{
			LinkedWallrunPoint.ForceWallRun(Player, WallrunDirection);
			Player.SnapCameraBehindPlayer();
		}

		Super::OnRespawnTriggered(Player);
	}

	UFUNCTION(CallInEditor)
	void AlignWithWallrunPoint()
	{
#if EDITOR
		if(LinkedWallrunPoint != nullptr)
		{
			FVector TargetLocation = LinkedWallrunPoint.ActorLocation;
			UGrappleWallrunPointComponent GrapplePointComp = UGrappleWallrunPointComponent::Get(LinkedWallrunPoint);
			TargetLocation += -GrapplePointComp.ForwardVector * 37;

			FRotator Rotation = WallrunDirection == ELeftRight::Left ? FRotator::MakeFromXZ(-GrapplePointComp.RightVector, ActorUpVector) : FRotator::MakeFromXZ(GrapplePointComp.RightVector, ActorUpVector);

			SetActorLocationAndRotation(TargetLocation, Rotation);

			//Reselect of actors to update transform Widgets / etc
			TArray<AActor> SelectedActors = Editor::SelectedActors;
			Editor::SelectActor(nullptr);
			Editor::SelectActors(SelectedActors);
		}
#endif
	}
};