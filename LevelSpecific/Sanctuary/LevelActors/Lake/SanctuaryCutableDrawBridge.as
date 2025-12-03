struct FSanctuaryCutableDrawBridgeChainSide
{
	UPROPERTY()
	bool bLeftChain = false;
}

UCLASS(Abstract)
class USanctuaryCutableDrawBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCutChain(FSanctuaryCutableDrawBridgeChainSide Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrawBridgePartlyFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrawBridgeFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMioMissCut() 
	{
		DevPrintStringEvent("Mio Miss Lightdisc");
	}
}

class ASanctuaryCutableDrawBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USceneComponent TopChainRootRight;

	UPROPERTY(DefaultComponent)
	USceneComponent TopChainRootLeft;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	bool bOneChainCut = false;

	bool bCutLeft = false;
	bool bCutRight = false;
	bool bFall = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleOnConstrainHit");
	}

	UFUNCTION()
	private void HandleOnConstrainHit(float Strength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	void ChainCut(bool bLeftChain)
	{
		if (bLeftChain)
			bCutLeft = true;
		else
			bCutRight = true;

		if (!bOneChainCut)
		{
			bOneChainCut = true;
			RotateComp.ConstrainAngleMax = 15.0;
			USanctuaryCutableDrawBridgeEventHandler::Trigger_OnDrawBridgePartlyFalling(this);
		}
		else
		{
			RotateComp.ConstrainAngleMax = 83.6;
			USanctuaryCutableDrawBridgeEventHandler::Trigger_OnDrawBridgeFalling(this);
			bFall = true;
		}
	}

	void MissCut()
	{
		if (!bOneChainCut)
		{
			USanctuaryCutableDrawBridgeEventHandler::Trigger_OnMioMissCut(this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartBridgeDown()
	{
		RotateComp.ConstrainAngleMax = 83.6;
	}
};