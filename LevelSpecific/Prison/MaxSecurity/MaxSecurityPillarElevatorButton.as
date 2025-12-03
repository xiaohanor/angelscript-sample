event void FMaxSecurityPillarElevatorButtonEvent(int Index);

UCLASS(Abstract)
class AMaxSecurityPillarElevatorButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface InactiveMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ActiveMaterial;

	UPROPERTY(EditInstanceOnly)
	int ButtonIndex;

	UPROPERTY()
	FMaxSecurityPillarElevatorButtonEvent OnActivated;

	UPROPERTY()
	FMaxSecurityPillarElevatorButtonEvent OnDeactivated;

	private TPerPlayer<bool> bPlayerOnButton;
	private bool bElevatorActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if (bElevatorActivated)
			return;

		CrumbPressButton(Player);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if (bElevatorActivated)
			return;

		CrumbReleaseButton(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPressButton(AHazePlayerCharacter Player)
	{
		check(!bPlayerOnButton[Player]);

		bool bWasPressed = IsButtonPressed();

		bPlayerOnButton[Player] = true;

		UpdateMeshMaterial();

		if(!bWasPressed && IsButtonPressed())
			OnActivated.Broadcast(ButtonIndex);
	}

	UFUNCTION(CrumbFunction)
	void CrumbReleaseButton(AHazePlayerCharacter Player, bool bReset = false)
	{
		bool bWasPressed = IsButtonPressed();

		bPlayerOnButton[Player] = false;

		UpdateMeshMaterial();

		if(bWasPressed && !IsButtonPressed())
			OnDeactivated.Broadcast(ButtonIndex);

		if(bReset)
		{
			// This prevents a bug that caused the actor to lose collision??
			AddActorCollisionBlock(this);
			RemoveActorCollisionBlock(this);
			Wiggle();
			Timer::SetTimer(this, n"Wiggle", 0.1);
		}
	}

	UFUNCTION()
	private void Wiggle()
	{
		ActorLocation = ActorLocation + FVector(0, 0, 0.01);
	}

	void OnElevatorActivated(bool bActivated)
	{
		bElevatorActivated = bActivated;

		UpdateMeshMaterial();
	}

	bool IsButtonPressed() const
	{
		if(bPlayerOnButton[0])
			return true;

		if(bPlayerOnButton[1])
			return true;

		return false;
	}

	private bool IsLit() const
	{
		if(IsButtonPressed())
			return true;

		if(bElevatorActivated)
			return true;

		return false;
	}

	private void UpdateMeshMaterial()
	{
		if(IsLit())
		{
			ButtonMesh.SetMaterial(0, ActiveMaterial);
		}
		else
		{
			ButtonMesh.SetMaterial(0, InactiveMaterial);
		}
	}
}