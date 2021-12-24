export const SingleNFT = ({ data }) => {
  return (
    <div className="flex-container">
      {data.map((item, idx) => {
        return (
          <div key={`auc_${idx}`} className="swiper-slide item" style={{ maxWidth: 350 }}>
            <div className="card">
              <div className="image-over">
                <img className="card-img-top" src={item.img} alt="" />
              </div>
              {/* Card Caption */}
              <div className="card-caption col-12 p-0">
                {/* Card Body */}
                <div className="card-body">
                  <div className="countdown-times mb-3">
                    <div
                      className="countdown d-flex justify-content-center"
                      data-date={item.date}
                    />
                  </div>
                  <a href="/item-details">
                    <h5 className="mb-0">{item.title}</h5>
                  </a>
                  <a
                    className="seller d-flex align-items-center my-3"
                    href="/item-details"
                  >
                    <img
                      className="avatar-sm rounded-circle"
                      src={item.seller_thumb}
                      alt=""
                    />
                    <span className="ml-2">{item.seller}</span>
                  </a>
                  <div className="card-bottom d-flex justify-content-between">
                    <span>{item.asset} on {item.blockchain}</span>
                    <span>{item.count}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};
