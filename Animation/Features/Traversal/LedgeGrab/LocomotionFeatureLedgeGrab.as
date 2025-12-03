struct FLocomotionFeatureLedgeGrabAnimData
{

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab")
    FHazePlayBlendSpaceData LedgeGrabBlendSpace;


	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Enter")
    FHazePlaySequenceData LedgeGrabEnter;


    UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|DropEnter")
    FHazePlaySequenceData LedgeGrabDropEnterLeft;

    UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|DropEnter")
    FHazePlaySequenceData LedgeGrabDropEnterRight;
    

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Dash")
    FHazePlaySequenceData LedgeGrabDashLeft;

    UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Dash")
    FHazePlaySequenceData LedgeGrabDashRight;



	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Mantle")
    FHazePlaySequenceData LedgeGrabMantleToMH;

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Mantle")
    FHazePlaySequenceData LedgeGrabMantleToRun;	

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Mantle")
    FHazePlaySequenceData LedgeGrabMantleToCrouch;	

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Mantle")
    FHazePlaySequenceData LedgeGrabMantleToCrouchWalk;	


	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrab|Cancel")
    FHazePlaySequenceData LedgeGrabCancel;



	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang")
    FHazePlayBlendSpaceData LedgeGrabHangBlendSpace;



	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Enter")
    FHazePlaySequenceData LedgeGrabHangEnter;



	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Mantle")
    FHazePlaySequenceData LedgeGrabHangMantleToMH;

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Mantle")
    FHazePlaySequenceData LedgeGrabHangMantleToRun;	

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Mantle")
    FHazePlaySequenceData LedgeGrabHangMantleToCrouch;	

	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Mantle")
    FHazePlaySequenceData LedgeGrabHangMantleToCrouchWalk;	


	UPROPERTY(BlueprintReadOnly, Category = "LedgeGrabHang|Cancel")
    FHazePlaySequenceData LedgeGrabHangCancel;


}



class ULocomotionFeatureLedgeGrab : UHazeLocomotionFeatureBase
{

    default Tag = n"LedgeGrab";

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLedgeGrabAnimData AnimData;

	

}
